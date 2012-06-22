#TODO: Make a command to join
#TODO: Make a command to list channels bot is in
#TODO: Make a command to part
#TODO: Make a command to send a message to a taget

class DirectCommand < Command
   def initialize
      super('DIRECT-COMMAND',
            'DIRECT-COMMAND <command>',
            'Puts a command directly through to the server.',
            {:adminLevel => 0})
   end

   @@instance = DirectCommand.new()

   def onCommand(responseInfo, args)
      responseInfo.server.sendMessage(args)
   end
end

class ListUsers < Command
   def initialize
      super('LIST-USERS',
            'LIST-USERS',
            'List all the users that the server knows about.',
            {:adminLevel => 0})
   end

   @@instance = ListUsers.new()

   def onCommand(responseInfo, args)
      channels = responseInfo.server.getChannels()

      channels.each_pair{|channel, users|
         chanList = "#{channel}: "

         users.each{|nick, user|
            prefix = ''
            if (user.isAuth?)
               prefix += '!'
            end

            if (user.ops)
               prefix += '@'
            end

            chanList += "#{prefix}^#{nick}(#{user.adminLevel}), "
         }
         responseInfo.respond(chanList.sub(/, $/, ''))
      }
   end
end

class LoadCommands < Command
   def initialize
      super('LOAD-COMMANDS',
            'LOAD-COMMANDS <command file path>',
            'Loads a command file.',
            {:adminLevel => 0})
   end

   @@instance = LoadCommands.new()

   def onCommand(responseInfo, args)
      args.strip!
      load args
      responseInfo.respond("Successfully Loaded #{args}")
   end
end
