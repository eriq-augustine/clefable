class ListGames < Command
   def initialize
      super('LIST-GAMES',
            'LIST-GAMES',
            'List all of the available games.',
            {:aliases => ['GAMES', 'GAME-LIST']})
   end

   @@instance = ListGames.new()

   def onCommand(responseInfo, args)
      schemasStr = ''

      schemas = Game::getGameSchemas()
      schemas.each_value{|schema|
         schemasStr += "#{schema[:name]}: #{schema[:desc]}; "
      }
      schemasStr.sub!(/; $/, '')

      responseInfo.respond(schemasStr)
   end
end

class MoveSyntax < Command
   def initialize
      super('MOVE-SYNTAX',
            'MOVE-SYNTAX',
            'Get the move syntax for a specific game.')
   end

   @@instance = MoveSyntax.new()

   def onCommand(responseInfo, args)
      args.strip!
      schema = Game::getGameSchemas()[args]

      if (!schema)
         responseInfo.respond("There is no game called: '#{args}'.")
      else
         responseInfo.respond("Move syntax for #{args}: #{schema[:moveSyntax]}.")
      end
   end
end
