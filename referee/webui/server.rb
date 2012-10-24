require 'em-websocket'
require 'set'

# Note ws.signature is enough to uniquely identify the connection.

class WebSocketServer
   def initialize(host, port)
      @host = host
      @port = port

      # { socketSig => {:socket => socket, :watching => 'list'|gameId} }
      @sockets = Hash.new()

      # All the games that people are watching.
      # { gameId => [socketIds] }
      @watchingGames = Hash.new{|hash, key| hash[key] = Array.new()}

      # All the sockets watching the main list.
      @socketsOnGameList = Set.new()

      # The current list of all games (already in JSON)
      @currentGameList = '[]'

      Game::registerGameWatcher(self)

      # Heads-up: This call blocks until the EM dies.
      EventMachine::WebSocket.start(:host => host, :port => port){|ws|
         ws.onopen{
            onOpen(ws, ws.signature)
         }

         ws.onmessage{|message|
            onMessage(ws.signature, message)
         }

         ws.onclose{
            onClose(ws.signature)
         }

         ws.onerror{|error|
            onError(ws.signature, error)
         }
      }
   end

   # TODO(eriq): This is pretty inefficient. Deltas could probably be commuinicated.
   # A game was added or subtracted.
   def gameListChanged()
      games = Game::getAllGames()

      if (games.size() > 0)
         @currentGameList = '['

         games.each{|game|
            @currentGameList += "{\"id\": #{game.id}," + 
                                " \"player1\": \"#{game.player1}\"," +
                                " \"player2\": \"#{game.player2}\"," +
                                " \"pending\": #{game.pending}," +
                                " \"gameType\": \"#{game.class}\"}, "
         }
         @currentGameList.sub!(/, $/, ']')
      else
         @currentGameList = '[]'
      end

      sendGameListToAllListeners()
   end

   def gameUpdated(gameId)
      # Don't bother to get these if there is noone to update.
      gameState = nil
      gameType = nil
      
      @watchingGames[gameId].each{|socketSig|
         if (!gameState)
            game = Game::getGameById(gameId)
            gameState = game.getState()
            gameType = game.class
         end

         sendGameState(socketSig, gameId, gameState, gameType)
      }
   end

   def gameDone(game)
      # TODO(eriq)
   end
   
   def sendMessage(socketSig, message)
      #puts "Sending Message: " + message

      #TEST
      # TODO(eriq): I think this may be hapening. Remove this guard when it is fixed.
      if (!@sockets[socketSig])
         Log(ERROR, "Closed socket is being referenced")
      else
         @sockets[socketSig][:socket].send(message)
      end
   end

   def onOpen(socket, socketSig)
      @sockets[socketSig] = {:socket => socket, :watching => 'list'}
      @socketsOnGameList.add(socketSig)
      sendGameList(socketSig)
   end

   def onClose(socketSig)
      if (@sockets[socketSig][:watching] != 'list')
         @watchingGames[@sockets[socketSig][:watching]].delete(socketSig)
      else
         @socketsOnGameList.delete(socketSig)
      end

      @sockets.delete(socketSig)
   end

   def onMessage(socketSig, message)
      begin
         obj = JSON.parse(message)
         
         if (obj['type'] == 'watchGame')
            @socketsOnGameList.delete(socketSig)
            @watchingGames[obj['gameId'].to_i] << socketSig
            sendGameState(socketSig, obj['gameId'].to_i)
         else
            LOG(WARN, "Message with unknown type recieved: #{obj}")
         end
      rescue JSON::ParserError => e
         puts e.message()
         puts e.backtrace.join("\n")
      end
   end

   def onError(socketSig, error)
      log(ERROR, "Socket error: #{error}")
   end

   def sendGameList(socketSig)
      sendMessage(socketSig, "{\"type\": \"gameList\", \"games\": #{@currentGameList}}")
   end

   def sendGameListToAllListeners()
      @socketsOnGameList.each{|socketSig|
         sendGameList(socketSig)
      }
   end

   def sendGameState(socketSig, gameId, gameState = nil, gameType = nil)
      game = Game::getGameById(gameId)
      if (!gameState)
         gameState = game.getState()
      end

      if (!gameType)
         gameType = game.class
      end

      message = "{\"type\": \"gameState\"," + 
                " \"gameType\": \"#{gameType}\"," + 
                " \"state\": #{gameState}}"
      sendMessage(socketSig, message)
   end
end
