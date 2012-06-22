class Help < Command
   def initialize
      super('HELP',
            'HELP [command]',
            'Get some help!')
   end

   @@instance = Help.new()

   def printAllCommands(responseInfo)
      message = "Commands: "

      @@commands.keys.sort.each{|name|
         command = @@commands[name]
        
         execResponse = responseInfo.fromUserInfo.canExecute?(command.requiredLevel)
         if (!command.requiredLevel || execResponse[:success])
            message += "#{name}, "
         end
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
