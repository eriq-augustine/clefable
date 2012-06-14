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

class About < Command
   def initialize
      super('ABOUT',
            'ABOUT [NAME | SOURCE]',
            'Learn about Clefable.')
   end

   @@instance = About.new()
   @@basic = 'Clefable is a chat bot started by ^Eriq'
   @@name = 'The name "Clefable" holds no special meaning.' +
            ' A random number was generated, and that pokemon was chosen.'
   @@source = 'Clefable was written all in Ruby and you can get the source at:' +
              ' https://github.com/eriq-augustine/clefable'

   def onCommand(responseInfo, args, onConsole)
      args.upcase!

      if (args == 'NAME')
         responseInfo.respond(@@name)
      elsif (args == 'SOURCE')
         responseInfo.respond(@@source)
      else
         responseInfo.respond(@@basic)
         responseInfo.respond(@@name)
         responseInfo.respond(@@source)
      end
   end
end
