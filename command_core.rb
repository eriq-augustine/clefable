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

   def self.invoke(server, fromUser, line, onConsole = false)
      if ((match = line.match(/^(\S+)\s*(.*)$/)) &&
          @@commands.has_key?(match[1]))

         if (!@@commands[match[1]].consoleOnly? ||
             (onConsole && @@commands[match[1]].consoleOnly?))
            @@commands[match[1]].onCommand(server, fromUser, match[2], onConsole)
         end
      else
         puts("[INFO] Unrecognized command: #{line}")

         if (!onConsole)
            server.chat("Unrecognized command. Try: HELP [command]")
         end
      end
   end

   def self.userPresentOnJoin(server, user)
      @@commands.each_value{|command|
         command.onUserPresence(server, user)
      }
   end

   def self.userJoined(server, user)
      @@commands.each_value{|command|
         command.onUserPresence(server, user)
         command.onUserJoin(server, user)
      }
   end

   def self.userLeft(server, user, reason)
      @@commands.each_value{|command|
         command.onUserLeave(server, user, reason)
      }
   end

   # Invoked when the command is used in chat
   def onCommand(server, fromUser, args, onConsole = false)
   end

   # Invoked on connect if the user is present, and if the user join
   def onUserPresence(server, user)
   end

   # Invoked if a user joins
   def onUserJoin(server, user)
   end

   # Invoked if a user leaves
   def onUserLeave(server, user, reason)
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

   def onCommand(server, fromUser, args, onConsole = false)
      if (match = args.strip.match(/^(\S+)\s+(.+)$/i))
         toUser = match[1]
         message = "Message from #{fromUser} recieved on #{Time.now()}: #{match[2]}"

         if (server.hasUser?(toUser))
            server.chat("#{toUser}: #{message}")
         else
            if (!@messageQueue.has_key?(toUser))
               @messageQueue[toUser] = Array.new()
            end

            @messageQueue[toUser] << message
         end
      else
         server.chat("USAGE: #{@usage}")
      end
   end

   def onUserPresence(server, user)
      if (@messageQueue.has_key?(user))
         @messageQueue[user].each{|message|
            server.chat("#{user}: #{message}")
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

   def onCommand(server, fromUser, args, onConsole = false)
      args.strip!

      if (args.length() > 0 && @@commands.has_key?(args))
         if (onConsole)
            puts "USAGE: #{@@commands[args].usage()}"
         else
            server.chat("USAGE: #{@@commands[args].usage()}")
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
            server.chat(message)
         end
      end
   end
end
