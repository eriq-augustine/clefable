# Make a move in a game.

class Move < Command
   def initialize
      super('MOVE',
            'MOVE <move>',
            'Make a move in your current game.' + 
             ' The syntax is different for every game, Eriq will make some info on it later.',
            {:aliases => ['MAKE-MOVE', 'TAKE-TURN', 'TURN']})
   end

   @@instance = Move.new()

   def onCommand(responseInfo, args)
      args.strip!

      if (args.length == 0)
         responseInfo.respond("You must enter something to make a move.")
         return
      end

      Game::makeMove(responseInfo, args)
   end
end
