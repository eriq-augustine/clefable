# TODO: Information is deiplayed about a command if they try and invoke it and it
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

   def respondPM(message, rewrite = true)
      if (@onConsole)
         puts message
      else
         server.chat(fromUser, message, rewrite)
      end
   end

   # Respond with the default behavior.
   # If the target is a channel, respond to the channel,
   #  otherwise respond to the user.
   def respond(message, rewrite = true)
      if (target.start_with?('#'))
         server.chat(target, message, rewrite)
      elsif (target == CONSOLE)
         puts message
      else
         server.chat(fromUser, message, rewrite)
      end
   end
end

class Command
   @@commands = Hash.new()

   attr_reader :usage, :name, :description, :admin, :requiredLevel

   def initialize(name, usage, description, options = {})
      @name = name
      @usage = usage
      @description = description

      @consoleOnly = false
      if (options.key?(:consoleOnly))
         @consoleOnly = options[:consoleOnly]
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
   end

   def consoleOnly?
      return @consoleOnly
   end

   def admin?
      return @admin
   end

   def skipLog?
      return @skipLog
   end

   # Return true if the command should be logged, false if it should not be logged.
   # target is usually a channel
   def self.invoke(responseInfo, line, onConsole = false)
      message = "Unrecognized command: [#{line}. Try: HELP [command]"
      log = true

      if (match = line.match(/^(\S+)\s*(.*)$/))
         commandName = match[1].upcase
         if (@@commands.has_key?(commandName))
            command = @@commands[commandName]
            #Console commands on the console only
            if (!command.consoleOnly? || (onConsole && command.consoleOnly?))
            # Check admin, console users are implicitly trusted
            # There should be a UserInfo associated with a non-console user
               if (!command.admin? ||
                   responseInfo.fromUser == CONSOLE ||
                   responseInfo.fromUserInfo && responseInfo.fromUserInfo.isAuth? &&
                   responseInfo.fromUserInfo.adminLevel <= command.requiredLevel)
                  command.onCommand(responseInfo, match[2], onConsole)
                  return !command.skipLog?
               else
                  log = !command.skipLog?
                  message = "You do not have the rights to execute this command." +
                            " This command requires admin level #{command.requiredLevel}"
                  if (!responseInfo.fromUserInfo)
                     message += " and you don't have any credentials, try REGISTER."
                  elsif (!responseInfo.fromUserInfo.isAuth?)
                     message += " and you are not AUTH'd, try AUTH."
                  else
                     message += " and you have level #{responseInfo.fromUserInfo.adminLevel}."
                  end
               end
            end
         end
      end

      responseInfo.respond(message)
      return log
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
