#TODO: Make a command to join
#TODO: Make a command to list channels bot is in
#TODO: Make a command to part
#TODO: Make a command to send a message to a taget

class DirectCommand < Command
   def initialize
      super('DIRECT-COMMAND',
            'DIRECT-COMMAND <command>',
            'Puts a command directly through to the server.',
            {:consoleOnly => true})
   end

   @@instance = DirectCommand.new()

   def onCommand(responseInfo, args, onConsole)
      responseInfo.server.sendMessage(args)
   end
end

class ListUsers < Command
   def initialize
      super('LIST-USERS',
            'LIST-USERS',
            'List all the users that the server knows about.',
            {:consoleOnly => true})
   end

   @@instance = ListUsers.new()

   def onCommand(responseInfo, args, onConsole)
      channels = responseInfo.server.getChannels()

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
            {:consoleOnly => true})
   end

   @@instance = LoadCommands.new()

   def onCommand(responseInfo, args, onConsole = false)
      load args
   end
end