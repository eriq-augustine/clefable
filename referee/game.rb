# The base for a game.
# Not only will instance of this represent a single match, subclasses will also embody the rules of a specific game.

class Game
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

   def self.addSchema(gameName, gameClass, gameDesc, moveSyntax)
      @@gameSchemas[gameName] = {:class => gameClass,
                                 :name => gameName,
                                 :desc => gameDesc,
                                 :moveSyntax => moveSyntax}
   end

   def self.newGame(gameName, player, pendingPlayer)
      if (!@@gameSchemas.has_key?(gameName))
         return nil
      end

      return @@gameSchemas[gameName][:class].new(player, pendingPlayer)
   end

   def self.getGameSchemas()
      return @@gameSchemas
   end

   # Does |pendingPlayer| have a pending game with |otherPlayer|.
   def self.hasPendingGame(pendingPlayer, otherPlayer)
      return @@pendingGames.has_key?(pendingPlayer) && @@pendingGames[pendingPlayer].has_key?(otherPlayer)
   end

   # |pendingPlayer| declines the game with |otherPlayer|.
   def self.declineGame(pendingPlayer, otherPlayer)
      return @@pendingGames[pendingPlayer].delete(otherPlayer)
   end

   # |pendingPlayer| accepts the game with |otherPlayer|.
   def self.ackGame(pendingPlayer, otherPlayer)
      game = @@pendingGames[pendingPlayer][otherPlayer]

      if (game)
         @@activeGames[pendingPlayer] = game
         @@activeGames[otherPlayer] = game
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

      game.takeTurn(responseInfo, args)
   end

   # Tell the game to finish and remove it from the active games map.
   def self.finishGame(player)
      game = @@activeGames[player]
      game.finish()

      @@activeGames.delete(game.player1)
      @@activeGames.delete(game.player2)

      return game
   end

   def self.getActiveGame(player)
      return @@activeGames[player]
   end

   attr_reader :player1, :player2, :id

   def initialize(startingPlayer, pendingPlayer)
      @@pendingGames[pendingPlayer][startingPlayer] = self

      @player1 = startingPlayer
      @player2 = pendingPlayer

      @@gameId += 1
      @id = @@gameId
   end
   
   def takeTurn(responseInfo, args)
      notreached("takeTurn() is not implemented.")
   end

   # Check win conditions.
   def gameOver?()
      notreached("gameOver?() is not implemented.")
   end

   # Do any cleanup.
   def finish()
   end
end
