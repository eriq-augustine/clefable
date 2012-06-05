#TODO: Make a command to join
#TODO: Make a command to list channels bot is in
#TODO: Make a command to part
#TODO: Make a command to send a message to a taget

class DirectCommand < Command
   def initialize
      super('DIRECT-COMMAND',
            'DIRECT-COMMAND <command>',
            'Puts a command directly through to the server.',
            true)
   end

   @@instance = DirectCommand.new()

   def onCommand(server, channel, fromUser, args, onConsole = false)
      server.sendMessage(channel, args)
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

   def onCommand(server, channel, fromUser, args, onConsole = false)
      channels = server.getUsers()

      channels.each_pair{|channel, users|
         puts "#{channel}"

         users.each{|nick, user|
            if (user.isAdmin)
               puts "   @#{nick}"
            else
               puts "   #{nick}"
            end
         }
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

   def onCommand(server, channel, fromUser, args, onConsole = false)
      load args
   end
end
