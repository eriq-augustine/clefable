class Help < Command
   def initialize
      super('HELP',
            'HELP [command]',
            'Get some help!')
   end

   @@instance = Help.new()

   def onCommand(responseInfo, args, onConsole = false)
      command = args.strip.upcase

      if (command.length() > 0 && @@commands.has_key?(command))
         responseInfo.respond("USAGE: #{@@commands[command].usage()}")
         responseInfo.respond("#{@@commands[command].description()}")
      else
         message = "Commands: "

         @@commands.each_pair{|name, command|
            if (onConsole || !command.consoleOnly?)
               message += "#{name}, "
            end
         }
         message.sub!(/, $/, '')
     
         responseInfo.respond(message)
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
   @@basic = 'Clefable is a chat bot started by Eriq'
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
