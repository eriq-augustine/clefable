require 'set'

class Help < Command
   def initialize
      super('HELP',
            'HELP [command]',
            'Get some help!',
            {:aliases => ['MAN']})
   end

   @@instance = Help.new()

   def printAllCommands(responseInfo)
      message = "Commands: "
      commandsToPrint = SortedSet.new()

      @@commands.values.each{|command|
         execResponse = responseInfo.fromUserInfo.canExecute?(command.requiredLevel)
         if (!command.requiredLevel || execResponse[:success])
            commandsToPrint << command.name
         end
      }

      commandsToPrint.each{|commandName|
         message += "#{commandName}, "
      }
      message.sub!(/, $/, '')
   
      responseInfo.respond(message)
   end

   def onCommand(responseInfo, args)
      commandStr = args.strip.upcase

      if (commandStr.length() > 0 && @@commands.has_key?(commandStr))
         command = @@commands[commandStr]
         
         execResponse = responseInfo.fromUserInfo.canExecute?(command.requiredLevel)
         if (!command.requiredLevel || execResponse[:success])
            responseInfo.respond("USAGE: #{command.usage()}")
            if (command.optionUsage())
               responseInfo.respond("OPTIONS: #{command.optionUsage()}")
            end
            responseInfo.respond("#{command.description()}")
            if (aliases = command.aliases)
               responseInfo.respond("ALIASES: #{aliases}")
            end
            return
         end
      end
      
      printAllCommands(responseInfo)
   end
end
