class StartGame < Command
   def initialize
      super('START-GAME',
            'START-GAME <GAME> [^]<OPPONENT>',
            'Start playing a game!',
            {:aliases => ['GAME-START']})
   end

   @@instance = StartGame.new()

   # TODO(eriq): PM the opponent.
   def onCommand(responseInfo, args)
      if (!(match = args.strip.match(/^(\S+)\s+\^?(\S+)$/)))
         responseInfo.respond("Improper syntax. Try `HELP START-GAME`.")
         return
      end

      game = match[1]
      opponent = match[2]

      if (Game::newGame(game, responseInfo.fromUser, opponent))
         responseInfo.respond("Game created between #{responseInfo.fromUser} and #{opponent}")
      else
         responseInfo.respond("No game found with name: #{game}.")
      end
   end
end

# Acknoledge a request to play a game.
class AckGame < Command
   def initialize
      super('ACK-GAME',
            'ACK-GAME [^]<OPPONENT>',
            'Acknowledge |OPPONENT|\'s request to play a game.',
            {:aliases => ['CHALLENGE-ACCEPTED', 'ACCEPT']})
   end

   @@instance = AckGame.new()

   def onCommand(responseInfo, args)
      if (!(match = args.strip.match(/^\^?(\S+)$/)))
         responseInfo.respond("Improper syntax. Try `HELP ACK-GAME`.")
         return
      end

      pendingPlayer = responseInfo.fromUser
      opponent = match[1]

      if (!Game::getPendingGame(pendingPlayer, opponent))
         responseInfo.respond("^#{pendingPlayer}: You do not have a pending game with ^#{opponent}. Try START-GAME.")
         return
      end

      game = Game::ackGame(pendingPlayer, opponent)
      responseInfo.respond("#{pendingPlayer}, #{opponent}: You game of #{game.class} has begun!")
   end
end

# Decline a request to play a game, or leave a current game.
class LeaveGame < Command
   def initialize
      super('LEAVE-GAME',
            'LEAVE-GAME [[^]<OPPONENT>]',
            'Leave the current game, or pending game with |OPPONENT|. If you do not specify an opponent, your current game is assumed.',
            {:aliases => ['QUIT', 'LEAVE', 'DECLINE', 'DECLINE-GAME']})
   end

   @@instance = LeaveGame.new()

   def onCommand(responseInfo, args)
      args.strip!

      player = responseInfo.fromUser

      if (args.length() > 0 && !Game::getActiveGame(player))
         if (!(match = args.strip.match(/^\^?(\S+)$/)))
            responseInfo.respond("Improper syntax. Try `HELP LEAVE-GAME`.")
            return
         end

         opponent = match[1]

         if (!Game::getPendingGame(player, opponent))
            responseInfo.respond("^#{player}: You do not have a pending game with ^#{opponent}.")
            return
         end

         game = Game::declineGame(player, opponent)
         responseInfo.respond("#{player}, #{opponent}: Your game of #{game.class} has been disbanded.")
      else
         game = Game::getActiveGame(player)
         if (!game)
            responseInfo.respond("^#{player}: You do not have a currently active game.")
            return
         end

         # TODO(eriq): Should this be finish?
         Game::finishGame(player)
         responseInfo.respond("^#{player}: You have left your currently active game with ^#{game.otherPlayer(player)}.")
      end
   end
end
