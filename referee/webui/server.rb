require 'em-websocket'

# Note ws.signature is enough to uniquely identify the connection.

class WebSocketServer
   def initialize(host, port)
      @host = host
      @port = port
      @sockets = Hash.new()

      # { gameId => [socketIds] }
      @watchingGames = Hash.new{|hash, key| hash[key] = Array.new()}

      Game::registerGameWatcher(self)

      EventMachine::WebSocket.start(:host => host, :port => port){|ws|
         ws.onopen{
            onOpen(ws.signature)
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

         @sockets[ws.signature] = ws
      }
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
   
   def sendMessage(socketSig, message)
      #puts "Sending Message: " + message

      @sockets[socketSig].send(message)
   end

   def onOpen(socketSig)
      games = Game::getActiveGames()
      gameList = ''

      games.each{|game|
         gameList += "{\"id\": #{game.id}," + 
                     " \"player1\": \"#{game.player1}\"," +
                     " \"player2\": \"#{game.player2}\"," +
                     " \"gameType\": \"#{game.class}\"}, "
      }
      gameList.sub!(/, $/, '')

      message = "{\"type\": \"gameList\", \"games\": [#{gameList}]}"

      sendMessage(socketSig, message)
   end

   def onClose(socketSig)
      @sockets.delete(socketSig)
   end

   def onMessage(socketSig, message)
      begin
         obj = JSON.parse(message)
         
         if (obj['type'] == 'watchGame')
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

#serverInstance = Server.new('localhost', '7070')
#serverInstance = Server.new('192.168.1.169', '7070')
# TODO(eriq): Make an official thread for this.
@@webuiThread = Thread.new{
   #serverInstance = WebSocketServer.new('0.0.0.0', '7070')
   begin
      #serverInstance = WebSocketServer.new('localhost', '7070')
      serverInstance = WebSocketServer.new('0.0.0.0', '7070')
   rescue Exception => detail
      log(ERROR, (detail.message() + "\n" + detail.backtrace.join("\n")))
      retry
   end
}
