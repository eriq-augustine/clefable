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

   def initialize(name, usage, description, consoleOnly = false)
      @name = name
      @usage = usage
      @description = description
      @consoleOnly = consoleOnly

      @@commands[@name.upcase] = self
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
   def self.invoke(responseInfo, line, onConsole = false)
      success = false
      if (match = line.match(/^(\S+)\s*(.*)$/))
         commandName = match[1].upcase
         if (@@commands.has_key?(commandName))
            command = @@commands[commandName]
            if (!command.consoleOnly? || (onConsole && command.consoleOnly?))
               command.onCommand(responseInfo, match[2], onConsole)
               success = true
            end
         end
      end

      if (!success)
         responseInfo.respond("Unrecognized command. Try: HELP [command]")
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

# TODO: use DB
class SendMessage < Command
   def initialize
      super('SEND-MESSAGE',
            'SEND-MESSAGE <to user> <message>',
            'Send a message to a user. If they are in the channel, it will just repeat it.' +
             'However if they are gone, the message will be sent when they return.')

      @messageQueue = Hash.new()
   end

   @@instance = SendMessage.new()

   def onCommand(responseInfo, args, onConsole = false)
      if (match = args.strip.match(/^(\S+)\s+(.+)$/i))
         toUser = match[1]
         message = "Message from #{responseInfo.fromUser} recieved on #{Time.now()}: #{match[2]}"

         if (responseInfo.server.hasUser?(toUser))
            responseInfo.server.chat(toUser, "#{toUser}: #{message}")
         else
            if (!@messageQueue.has_key?(toUser))
               @messageQueue[toUser] = Array.new()
            end

            @messageQueue[toUser] << message
         end
      else
         responseInfo.respond("USAGE: #{@usage}")
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

   def onCommand(responseInfo, args, onConsole = false)
      args.strip!

      if (args.length() > 0 && @@commands.has_key?(args))
         responseInfo.respond("USAGE: #{@@commands[args].usage()}")
         responseInfo.respond("#{@@commands[args].description()}")
      else
         message = "Commands: "

         @@commands.each_pair{|name, command|
            if (onConsole || !command.consoleOnly?)
               message += "#{name}, "
            end
         }
         message.sub!(/, $/, '')
     
         responseInfo.respond(message)
      end
   end
end

class About < Command
   def initialize
      super('ABOUT',
            'ABOUT [NAME | SOURCE]',
            'Learn about Clefable.')
   end

   @@instance = About.new()
   @@basic = 'Clefable is a chat bot started by Eriq'
   @@name = 'The name "Clefable" holds no special meaning.' +
            ' A random number was generated, and that pokemon was chosen.'
   @@source = 'Clefable was written all in Ruby and you can get the source at:' +
              'https://github.com/eriq-augustine/clefable'

   def onCommand(responseInfo, args, onConsole)
      if (args == 'NAME')
         responseInfo.respond(@@name)
      elsif (args == 'SOURCE')
         responseInfo.respond(@@source)
      else
         responseInfo.respond(@@basic)
         responseInfo.respond(@@name)
         responseInfo.respond(@@source)
      end
   end
end
