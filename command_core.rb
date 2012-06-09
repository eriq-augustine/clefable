class ResponseInfo
   def initialize(server, fromUser, target)
      @server = server
      @fromUser = fromUser
      @target = target

      @onConsole = (fromUser == CONSOLE)
   end

   attr_reader :server, :fromUser, :target

   def respondPM(message)
      if (@onConsole)
         puts message
      else
         server.chat(fromUser, message)
      end
   end

   # Respond with the default behavior.
   # If the target is a channel, respond to the channel,
   #  otherwise respond to the user.
   def respond(message)
      if (target.start_with?('#'))
         server.chat(target, message)
      elsif (target == CONSOLE)
         puts message
      else
         server.chat(fromUser, message)
      end
   end
end

class Command
   @@commands = Hash.new()

   def initialize(name, usage, description, options = {})
      @name = name
      @usage = usage
      @description = description

      @consoleOnly = false
      if (options.key?(:consoleOnly))
         @consoleOnly = options[:consolOnly]
      end

      @skipLog = false
      if (options.key?(:skipLog))
         @skipLog = options[:skipLog]
      end

      @@commands[@name.upcase] = self
   end

   def consoleOnly?
      return @consoleOnly
   end
   
   def skipLog?
      return @skipLog
   end

   def usage
      return @usage
   end

   def description
      return @description
   end

   # Return true if the command should be logged, false if it should not be logged.
   # target is usually a channel
   def self.invoke(responseInfo, line, onConsole = false)
      if (match = line.match(/^(\S+)\s*(.*)$/))
         commandName = match[1].upcase
         if (@@commands.has_key?(commandName))
            command = @@commands[commandName]
            if (!command.consoleOnly? || (onConsole && command.consoleOnly?))
               command.onCommand(responseInfo, match[2], onConsole)
               return !command.skipLog?
            end
         end
      end

      responseInfo.respond("Unrecognized command. Try: HELP [command]")
      return true
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
   def onCommand(responseInfo, args, onConsole = false)
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
