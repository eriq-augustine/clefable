class Command
   @@commands = Hash.new()

   def initialize(name, usage, description, consoleOnly = false)
      @name = name
      @usage = usage
      @description = description
      @consoleOnly = consoleOnly

      @@commands[@name] = self
   end

   def consoleOnly?
      return @consoleOnly
   end

   def usage
      return @usage
   end

   def description
      return @description
   end

   # target is usually a channel
   def self.invoke(server, target, fromUser, line, onConsole = false)
      if ((match = line.match(/^(\S+)\s*(.*)$/)) &&
          @@commands.has_key?(match[1]))

         if (!@@commands[match[1]].consoleOnly? ||
             (onConsole && @@commands[match[1]].consoleOnly?))
            @@commands[match[1]].onCommand(server, target, fromUser, match[2], onConsole)
         end
      else
         puts("[INFO] Unrecognized command: #{line}")

         if (!onConsole)
            respondTo = target
            # If invocation was in a channel, respond to the channel,
            #  otherwise respond back to the user
            if (!target.start_with?('#'))
               respondTo = fromUser
            end
            server.chat(respondTo, "Unrecognized command. Try: HELP [command]")
         end
      end
   end

   def self.userPresentOnJoin(server, channel, user)
      @@commands.each_value{|command|
         command.onUserPresence(server, channel, user)
      }
   end

   def self.userJoined(server, channel, user)
      @@commands.each_value{|command|
         command.onUserPresence(server, channel, user)
         command.onUserJoin(server, channel, user)
      }
   end

   def self.userLeft(server, channel, user, reason)
      @@commands.each_value{|command|
         command.onUserLeave(server, channel, user, reason)
      }
   end

   # Invoked when the command is used in chat
   def onCommand(server, channel, fromUser, args, onConsole = false)
   end

   # Invoked on connect if the user is present, and if the user join
   def onUserPresence(server, channel, user)
   end

   # Invoked if a user joins
   def onUserJoin(server, channel, user)
   end

   # Invoked if a user leaves
   def onUserLeave(server, channel, user, reason)
   end
end

class SendMessage < Command
   def initialize
      super('SEND-MESSAGE',
            'SEND-MESSAGE <to user> <message>',
            'Send a message to a user. If they are in the channel, it will just repeat it.' +
             'However if they are gone, the message will be sent when they return.')

      @messageQueue = Hash.new()
   end

   @@instance = SendMessage.new()

   def onCommand(server, channel, fromUser, args, onConsole = false)
      if (match = args.strip.match(/^(\S+)\s+(.+)$/i))
         toUser = match[1]
         message = "Message from #{fromUser} recieved on #{Time.now()}: #{match[2]}"

         if (server.hasUser?(toUser))
            server.chat(channel, "#{toUser}: #{message}")
         else
            if (!@messageQueue.has_key?(toUser))
               @messageQueue[toUser] = Array.new()
            end

            @messageQueue[toUser] << message
         end
      else
         server.chat(channel, "USAGE: #{@usage}")
      end
   end

   def onUserPresence(server, channel, user)
      if (@messageQueue.has_key?(user))
         @messageQueue[user].each{|message|
            server.chat(channel, "#{user}: #{message}")
         }
         @messageQueue.delete(user)
      end
   end
end

class Help < Command
   def initialize
      super('HELP',
            'HELP [command]',
            'Get some help!')
   end

   @@instance = Help.new()

   def onCommand(server, channel, fromUser, args, onConsole = false)
      args.strip!

      if (args.length() > 0 && @@commands.has_key?(args))
         if (onConsole)
            puts "USAGE: #{@@commands[args].usage()}"
            puts "#{@@commands[args].description()}"
         else
            server.chat(channel, "USAGE: #{@@commands[args].usage()}")
            server.chat(channel, "#{@@commands[args].description()}")
         end
      else
         message = "Commands: "

         @@commands.each_pair{|name, command|
            if (onConsole || !command.consoleOnly?)
               message += "#{name}, "
            end
         }
         message.sub!(/, $/, '')
      
         if (onConsole)
            puts message
         else
            server.chat(channel, message)
         end
      end
   end
end
