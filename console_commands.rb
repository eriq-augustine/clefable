class DirectCommand < Command
   def initialize
      super('DIRECT-COMMAND',
            'DIRECT-COMMAND <command>',
            'Puts a command directly through to the server.',
            true)
   end

   @@instance = DirectCommand.new()

   def onCommand(server, fromUser, args, onConsole = false)
      server.sendMessage(args)
   end
end

class ListUsers < Command
   def initialize
      super('LIST-USERS',
            'LIST-USERS',
            'List all the users that the server knows about.',
            true)
   end

   @@instance = ListUsers.new()

   def onCommand(server, fromUser, args, onConsole = false)
      users = server.getUsers()

      users.each_pair{|key, val|
         if (val.isAdmin)
            puts "@#{key}"
         else
            puts "#{key}"
         end
      }
   end
end

class LoadCommands < Command
   def initialize
      super('LOAD-COMMANDS',
            'LOAD-COMMANDS <command file path>',
            'Loads a command file.',
            true)
   end

   @@instance = LoadCommands.new()

   def onCommand(server, fromUser, args, onConsole = false)
      load args
   end
end
