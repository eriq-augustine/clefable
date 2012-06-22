class Help < Command
   def initialize
      super('HELP',
            'HELP [command]',
            'Get some help!')
   end

   @@instance = Help.new()

   def printAllCommands(responseInfo, onConsole)
      message = "Commands: "

      @@commands.keys.sort.each{|name|
         command = @@commands[name]
         
         if (!command.admin? ||
               responseInfo.fromUserInfo && responseInfo.fromUserInfo.isAuth? &&
               responseInfo.fromUserInfo.adminLevel <= command.requiredLevel)
            if (onConsole || !command.consoleOnly?)
               message += "#{name}, "
            end
         end
      }
      message.sub!(/, $/, '')
   
      responseInfo.respond(message)
   end

   def onCommand(responseInfo, args, onConsole)
      commandStr = args.strip.upcase

      if (commandStr.length() > 0 && @@commands.has_key?(commandStr))
         command = @@commands[commandStr]

         if (!command.admin? ||
             responseInfo.fromUserInfo && responseInfo.fromUserInfo.isAuth? &&
             responseInfo.fromUserInfo.adminLevel <= command.requiredLevel)
            if (onConsole || !command.consoleOnly?)
               responseInfo.respond("USAGE: #{command.usage()}")
               responseInfo.respond("#{command.description()}")
               if (aliases = command.aliases)
                  responseInfo.respond("ALIASES: #{aliases}")
               end
            else
               printAllCommands(responseInfo, onConsole)
            end
         else
            printAllCommands(responseInfo, onConsole)
         end
      else
         printAllCommands(responseInfo, onConsole)
      end
   end
end
