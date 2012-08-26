class Alias < Command
   def initialize
      super('ALIAS',
            'ALIAS [command]',
            'Check the aliases for a specific command.',
            {:aliases => ['ALIASES']})
   end

   @@instance = Alias.new()

   def onCommand(responseInfo, args)
      commandStr = args.strip.upcase

      if (commandStr.length() == 0)
         responseInfo.respond('You must enter a command.')
      elsif (!@@commands.has_key?(commandStr))
         responseInfo.respond("That command doesn't exist.")
      else 
         command = @@commands[commandStr]
         execResponse = responseInfo.fromUserInfo.canExecute?(command.requiredLevel)
         if (!command.requiredLevel || execResponse[:success])
            if (aliases = command.aliases)
               responseInfo.respond("#{command.name} has the following aliases: #{aliases}")
            else
               responseInfo.respond("#{command.name}: has no aliases.")
            end
         else
            responseInfo.respond("That command doesn't exist.")
         end
      end
   end
end
