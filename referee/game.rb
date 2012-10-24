# The base for a game.
# Not only will instance of this represent a single match, subclasses will also embody the rules of a specific game.

class Game
   ## BEGIN Static section ##

   public

      GAME_OVER_NOT = -1
      GAME_OVER_CANCELED = 0
      GAME_OVER_TIE = 1
      GAME_OVER_PLAYER1 = 2
      GAME_OVER_PLAYER2 = 3

      def self.newGame(gameName, player, pendingPlayer)
         if (!@@gameSchemas.has_key?(gameName))
            return nil
         end

         return @@gameSchemas[gameName][:class].new(player, pendingPlayer)
      end

      def self.getGameSchemas()
         return @@gameSchemas
      end

      # Order of players does not matter.
      def self.getPendingGame(player1, player2)
         if (@@pendingGames.has_key?(player1))
            if (@@pendingGames[player1].has_key?(player2))
               return @@pendingGames[player1][player2]
            end
         end
         
         if (@@pendingGames.has_key?(player2))
            if (@@pendingGames[player2].has_key?(player1))
               return @@pendingGames[player2][player1]
            end
         end

         return nil
      end

      # |player1| declines the game with |player2|.
      def self.declineGame(player1, player2)
         game = removePendingGame(player1, player2)
         @@allGames.delete(game.id)
         notifyWatchersGameListChanged()

         if (!game)
            LOG(ERROR, "Non-existant game declined between #{player1} and #{player2}.")
         end

         return game
      end

      def self.ackGame(player1, player2)
         game = removePendingGame(player1, player2)

         if (game)
            @@activeGames[player1] = game
            @@activeGames[player2] = game
            game.pending = false
            notifyWatchersGameUpdated(game.id)
            notifyWatchersGameListChanged()
         else
            LOG(ERROR, "Non-existant game ack'd between #{player1} and #{player2}.")
         end

         return game
      end

      def self.makeMove(responseInfo, args)
         player = responseInfo.fromUser
         game = getActiveGame(player)

         if (!game)
            # TODO(eriq): Tell the player what pending games they have.
            responseInfo.respond("^#{player}: You are not currently in a game.")
            return
         end

         # Don't notify if the game is over, finishGame() will do that.
         if (!game.takeTurn(responseInfo, args))
            notifyWatchersGameUpdated(game.id)
         end
      end

      # Tell the game to finish and remove it from the active games map.
      def self.finishGame(player)
         game = @@activeGames[player]
         game.finish()

         @@activeGames.delete(game.player1)
         @@activeGames.delete(game.player2)
         @@allGames.delete(game.id)
         
         notifyWatchersGameListChanged()
         notifyWatchersGameDone(game)

         return game
      end

      def self.getActiveGame(player)
         return @@activeGames[player]
      end

      def self.getAllGames()
         return @@allGames.values()
      end

      def self.getGameById(id)
         return @@allGames[id]
      end

      def self.registerGameWatcher(gameWatcher)
         @@watchers << gameWatcher
      end

   protected

      def self.addSchema(gameName, gameClass, gameDesc, moveSyntax)
         @@gameSchemas[gameName] = {:class => gameClass,
                                    :name => gameName,
                                    :desc => gameDesc,
                                    :moveSyntax => moveSyntax}
      end

   private

      def self.notifyWatchersGameUpdated(id)
         @@watchers.each{|watcher|
            watcher.gameUpdated(id)
         }
      end

      def self.notifyWatchersGameDone(game)
         @@watchers.each{|watcher|
            watcher.gameDone(game)
         }
      end

      def self.notifyWatchersGameListChanged()
         @@watchers.each{|watcher|
            watcher.gameListChanged()
         }
      end
    
      def self.removePendingGame(player1, player2)
         if (@@pendingGames.has_key?(player1))
            if (@@pendingGames[player1].has_key?(player2))
               return @@pendingGames[player1].delete(player2)
            end
         end
         
         if (@@pendingGames.has_key?(player2))
            if (@@pendingGames[player2].has_key?(player1))
               return @@pendingGames[player2].delete(player1)
            end
         end

         return nil
      end

      # All the playable game types.
      # {name => Game (the class, not an instance)}
      @@gameSchemas = (defined?(@@gameSchemas)) ? @@gameSchemas : Hash.new()

      # All the pending games (games that have been requested by one player, but not yet accepted by the other).
      # {player (who has not acknowledged) => {player (who made the request) => Game} }
      @@pendingGames = (defined?(@@pendingGames)) ? @@pendingGames : Hash.new{|hash, key| hash[key] = Hash.new()}

      # All of the currently active games.
      # {player => Game}
      # Each player will key to the same game.
      @@activeGames = (defined?(@@activeGames)) ? @@activeGames : Hash.new()

      @@gameId = (defined?(@@gameId)) ? @@gameId : 0

      # Keyed by id
      @@allGames = (defined?(@@allGames)) ? @@allGames : Hash.new()

      # All of these get updated when a move is made.
      @@watchers = (defined?(@@watchers)) ? @@watchers : Array.new()

   ## END Static sction

   public

      attr_reader :player1, :player2, :id, :gameOverStatus
      attr_accessor :pending

      def initialize(startingPlayer, pendingPlayer)
         @@gameId += 1
         @id = @@gameId
      
         @@pendingGames[pendingPlayer][startingPlayer] = self
         @@allGames[@id] = self

         @pending = true
         @player1 = startingPlayer
         @player2 = pendingPlayer

         # This should be called before Game::finishGame is called.
         @gameOverStatus =  GAME_OVER_NOT
         
         Game::notifyWatchersGameListChanged()
      end
    
      # Return true if the game is over, false otherwise.
      def takeTurn(responseInfo, args)
         notreached("takeTurn() is not implemented.")
         return false
      end

      def otherPlayer(player)
         return player == @player1 ? @player2 : @player1
      end

      # Check win conditions.
      def gameOver?()
         notreached("gameOver?() is not implemented.")
      end

      # Do any cleanup and return the winner.
      # Return a GAME_OVER_*.
      # Usually, it is fine to leave it at this and set the status when you know it.
      def finish()
         return @gameOverStatus
      end

      # Get the state of the game. This will be directly passed as a to the webui.
      def getState
         return "{}"
      end
end
