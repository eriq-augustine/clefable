# TODO: Information is displayed about a command if they try and invoke it and it
#  requires admin. Should this info be hidden?

class ResponseInfo
   attr_reader :server, :fromUser, :target, :fromUserInfo

   def initialize(server, fromUser, target, fromUserInfo)
      @server = server
      @fromUser = fromUser
      @target = target
      @fromUserInfo = fromUserInfo

      @onConsole = (fromUser == CONSOLE)
   end

   def respondPM(message, options = {})
      if (@onConsole)
         puts message
      else
         server.chat(fromUser, message, options)
      end
   end

   # Respond with the default behavior.
   # If the target is a channel, respond to the channel,
   #  otherwise respond to the user.
   def respond(message, options = {})
      if (target.start_with?('#'))
         server.chat(target, message, options)
      elsif (target == CONSOLE)
         puts message
      else
         server.chat(fromUser, message, options)
      end
   end
end

class Command
   @@commands = Hash.new()

   attr_reader :usage, :name, :description, :admin, :requiredLevel, :aliases, :optionUsage

   # Availble options:
   #  :adminLevel (int) both requires that a user is an admin, and that the required level is met on invocation
   #  :skipLog (bool) Do not log this entry, great for passwords
   #  :aliases (array) All the different aliases for a command.
   #  :optionUsage (string) The correct usage for options
   def initialize(name, usage, description, options = {})
      @name = name
      @usage = usage
      @description = description

      @optionUsage = nil
      if (options.key?(:optionUsage))
         @optionUsage = options[:optionUsage]
      end

      @skipLog = false
      if (options.key?(:skipLog))
         @skipLog = options[:skipLog]
      end

      @admin = false
      if (options.key?(:adminLevel))
         @admin = true
         @requiredLevel = options[:adminLevel].to_i
      end

      @@commands[@name.upcase] = self

      @aliases = nil
      if (options[:aliases])
         @aliases = options[:aliases]
         options[:aliases].each{|aliasName|
            @@commands[aliasName.upcase] = self
         }
      end
   end

   def admin?
      return @admin
   end

   def skipLog?
      return @skipLog
   end

   # Check to see if logging should be skipped for this supposed invocation.
   # The log is only skipped if the command exists, and it has skipLog? return true.
   def self.skipLog?(line)
      if (!(match = line.match(/^(\S+)\s*(.*)$/)))
         return false
      end

      commandName = match[1].upcase
      if (!@@commands.has_key?(commandName))
         return false
      end

      return command.skipLog?()
   end

   # Return true if the command should be logged, false if it should not be logged.
   # target is usually a channel
   def self.invoke(responseInfo, line)
      if (!(match = line.match(/^(\S+)\s*(.*)$/)))
         responseInfo.respond("#{responseInfo.fromUser}: Please say something when talking to me.")
         return true
      end

      commandName = match[1].upcase
      if (NlpBot.instance.chatMode)
         # The command was not found. In the NLP context, this is a standard utterance.
         # In NLP, there are no unrecognized commands.
         if (NlpBot.instance.handleUtterance(responseInfo, line.strip))
            return true
         end
      end

      if (!@@commands.has_key?(commandName))
         responseInfo.respond("#{responseInfo.fromUser}: Command (#{match[1]}) not found." +
                              " If you want to chat, try ENTER-CHAT-MODE.")
         return true
      end

      command = @@commands[commandName]
      execLevelResponse = responseInfo.fromUserInfo.canExecuteAtLevel?(command.requiredLevel)

      if (command.requiredLevel && !execLevelResponse[:success])
         responseInfo.respond(execLevelResponse[:error])
         return !command.skipLog?
      end

      # TODO(eriq): User API goes here.

      command.onCommand(responseInfo, match[2])
      return !command.skipLog?
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

   def self.userInfo(user, infoType, info)
      @@commands.each_value{|command|
         command.onUserInfo(user, infoType, info)
      }
   end

   # Invoked when the command is used in chat
   def onCommand(responseInfo, args)
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

   # This is just for general user info that is published.
   # The information is blind passed (can be nil).
   # It is up to the specific command to look for the info it wants.
   def onUserInfo(user, infoType, info)
   end
end
