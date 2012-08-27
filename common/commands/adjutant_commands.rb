# TODO: Make a commmand to reload then entire system (maybe not core?)
#TODO: Make a command to send a message to a taget

class DirectCommand < Command
   def initialize
      super('DIRECT-COMMAND',
            'DIRECT-COMMAND <command>',
            'Puts a command directly through to the server.',
            {:adminLevel => 0,
             :aliases => ['DIRECT-MESSAGE', 'DIRECT']})
   end

   @@instance = DirectCommand.new()

   def onCommand(responseInfo, args)
      OutputThread.instance.queueMessage(args, 0)
   end
end

class SendDirectMessage < Command
   def initialize
      super('SEND-DIRECT-MESSAGE',
            'SEND-DIRECT-MESSGAE <target> <message>',
            'Sends a message as Clefable to |target|. Becareful, format is not even checked.',
            {:adminLevel => 0,
             :aliases => ['TALK', 'MESSAGE', 'MSG']})
   end

   @@instance = SendDirectMessage.new()

   def onCommand(responseInfo, args)
      if (!(match = args.strip.match(/^(#?\S+)\s+(.*)$/)))
         responseInfo.respond('You need a target (channel or user) and text to send a message.')
         return
      end

      target = match[1]
      text = match[2]

      OutputThread.instance.queueMessage("PRIVMSG #{target} :#{text}", 0)
   end
end

class ListUsers < Command
   def initialize
      super('LIST-USERS',
            'LIST-USERS',
            'List all the users that the server knows about.',
            {:adminLevel => 0,
             :aliases => ['WHO', 'W']})
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
            {:adminLevel => 0,
             :aliases => ['LOAD-COMMAND', 'LD', 'LOAD']})
   end

   @@instance = LoadCommands.new()

   def onCommand(responseInfo, args)
      args.strip!
      load args
      responseInfo.respond("Successfully Loaded #{args}")
   end
end

class Join < Command
   def initialize
      super('JOIN',
            'JOIN <channel>',
            'Make Clefable join a channel. If the channel is protected, the join may fail.',
            {:adminLevel => 0})
   end

   @@instance = Join.new()

   def onCommand(responseInfo, args)
      args.strip!

      if (!args.start_with?('#'))
         responseInfo.respond('Channels must start with a \'#\'.')
      else
         OutputThread.instance.queueMessage("JOIN #{args}", 0)
         responseInfo.respond("Attempting to join #{args}")
      end
   end
end

class Part < Command
   def initialize
      super('PART',
            'PART [<channel>]',
            'Make Clefable leave a channel. If the channel is missing, the current channel is assumed.',
            {:adminLevel => 0})
   end

   @@instance = Part.new()

   def onCommand(responseInfo, args)
      args.strip!

      if (args.size == 0)
         channel = responseInfo.target

         # In a PM
         if (!channel.start_with?('#'))
            responseInfo.respond('Doesn\'t make sense to PART from a PM.')
            return
         end
      else
         channel = args
         
         if (!channel.start_with?('#'))
            responseInfo.respond('Channels must start with a \'#\'.')
            return
         end
      end

      OutputThread.instance.queueMessage("PART #{channel} PART_command_was_issued_by_#{responseInfo.fromUser}", 0)
      responseInfo.respond("Attempting to part #{channel}")
   end
end

class Channels < Command
   def initialize
      super('CHANNELS',
            'CHANNELS',
            'List all channels that Clefable is in.',
            {:adminLevel => 0,
             :aliases => ['LIST-CHANNELS']})
   end

   @@instance = Channels.new()

   def onCommand(responseInfo, args)
      channels = responseInfo.server.getChannels()

      chanList = "Channels: "
      channels.each_key{|channel|
         chanList += "#{channel}, "
      }
      responseInfo.respond(chanList.sub(/, $/, ''))
   end
end
