# This class should only be new()'d once.
# If you need to relad it for some reason, use reload()
class Bot
   include DB
   include TextSplit

   attr_reader :channels, :users, :rewriteRules, :emailMap

   # This is the currently active bot.
   # It may actually be something like a ClefableBot.
   @@instance = nil

   def self.instance
      return @@instance
   end

   def initialize()
      # { channelName => { userName => user } }
      @channels = Hash.new{|hash, key| hash[key] = Hash.new() }

      # { userName => user }
      @users = Hash.new()

      # { target => rewrite }
      @rewriteRules = getRewriteRules()

      @emailMap = Hash.new()
      initEmailMap()

      @@instance = self
   end

   # Wrapper for InputQueue.queueMessage()
   def sendMessage(message, delay = 0)
      OutputThread.instance.queueMessage(message, delay)
   end

   def join(channel)
      sendMessage("JOIN #{channel}")
      log(INFO, "Joined #{channel}")
   end

   def whois(nick)
      sendMessage("WHOIS #{nick}")
   end

   # Available options:
   #  :rewrite: whether to invoke the rewrite engine (default: true)
   #  :delay: ensure a delay of at least this much, may be more because of flood control (default: 0)
   def chat(channel, message, options = {})
      if (!options[:rewrite] || options[:rewrite])
         @rewriteRules.each_pair{|target, rewrite|
            message.gsub!(/#{target}/i, rewrite)
         }
      end

      delay = options[:delay]
      if (!delay)
         delay = 0
      end

      messages = splitText(message)
      messages.each{|splitMessage|
         sendMessage("PRIVMSG #{channel} :#{splitMessage}", delay)
      }
   end

   def ensureUser(user, channel, ops)
      if (!@users.has_key?(user))
         userInfo = User.new(user, ops)
         @users[user] = userInfo
         @channels[channel][user] = userInfo
      elsif (!@channels[channel].has_key?(user))
         @channels[channel][user] = @users[user]
      end
   end

   def handleServerInput(message)
      message.strip!
      log(DEBUG, "Server says: #{message}")

      #TEST
      puts message

      # PING :<server>
      if (match = message.match(/^PING\s:(.*)$/))
         sendMessage("PONG :#{match[1]}")
      # :<from user>!<from user>@<from address> PRIVMSG <to> :<message>
      # <to> is usually a channel
      elsif (match = message.match(/^:([^!]*)!([^@]*)@([^\s]*)\sPRIVMSG\s([^\s]*)\s:(.*)$/))
         fromUser = match[1]
         target = match[4]
         content = match[5].strip

         responseInfo = ResponseInfo.new(self, fromUser, target, @users[fromUser])

         logMessage = true
         # If sent message is started with "#{IRC_NICK}:" or "#{SHORT_NICK}:" or "#{TRIGGER}"
         if (commandMatch = content.strip.match(/^((?:#{IRC_NICK}:)|(?:#{SHORT_NICK}:)|(?:#{TRIGGER}))\s*(.+)$/i))
            logMessage = Command.invoke(responseInfo, commandMatch[2])
         # If message was sent in a PM
         elsif (target == IRC_NICK)
            logMessage = Command.invoke(responseInfo, content)
         end

         if (logMessage)
            logChat(fromUser, target, content)
         end
      # Recieving user names from the server
      # ones with ops names are prepended with '@'
      # :<server> 353 <nick> @ <channel> :<user list (space seperated)>
      elsif (match = message.match(/^:(\S+)\s+353\s+(\S+)\s+@\s+(\S+)\s+:(.*)$/))
         users = match[4].split(/\s+/)
         channel = match[3]

         users.each{|user|
            user.strip!
            ops = false

            if (user.start_with?('@'))
               ops = true
               user.sub!(/^@/, '')
            end

            ensureUser(user, channel, ops)
         }
      # :pratchett.freenode.net 311 TEST_BOT eriq_home ~eriq_home c-50-131-15-127.hsd1.ca.comcast.net * :eaugusti@chromium.org
      # :<requester irc server> 311 <requester name> <target user> ~<target nick (again?)> <address> * :<extra user info>
      elsif (match = message.match(/^:(\S+)\s+311\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\*\s+:(.*)$/))
         user = match[3]
         address = match[5]
         extraInfo = match[6]

         puts "User: #{user}, Address: #{address}, Info: #{extraInfo}"

         if (@users[user])
            @users[user].address = address
            @users[user].extraInfo = extraInfo
            Command.userInfo(user, 'WHOIS', nil)
         else
            log(WARN, "Got userinfo on an unknown user: #{user}.")
         end
      # :<from user>!<from user>@<from address> JOIN <channel>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sJOIN\s(\S*)$/))
         user = match[1]
         channel = match[4]
         ensureUser(user, channel, false)
         Command.userJoined(self, channel, user)
         logChat(user, channel, "** JOIN'd #{channel} **")
      # Clefable PART'ed
      # :Clefable_BOT!<something like ~Clefable_>@<from address> PART <channel>
      elsif (match = message.match(/^:#{IRC_NICK}!([^@]*)@(\S*)\sPART\s(\S*)\s*$/))
         channel = match[3]
         @channels.delete(channel)
      # :eriq_home!~eriq_home@c-50-131-15-127.hsd1.ca.comcast.net QUIT :Quit: Leaving
      # :<from user>!<from user>@<from address> QUIT :<reason>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sQUIT\s+:(.*)$/))
         user = match[1]
         reason = match[4]

         @users.delete(user)
         @channels.each_value{|channelUsers|
            channelUsers.delete(user)
            Command.userLeft(self, ALL_CHANNELS, user, reason)
         }

         logChat(user, ALL_CHANNELS, "** QUIT'd Resson: #{reason} **")
      # :eriq!~eriq@c-50-131-15-127.hsd1.ca.comcast.net PART #eriq_secret
      # :eriq!~eriq@c-50-131-15-127.hsd1.ca.comcast.net PART #eriq_secret :"Leaving"
      # :<from user>!<from user>@<from address> PART <channel>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sPART\s(\S*)/))
         user = match[1]
         channel = match[4]
         reason = match[5]

         @channels[channel].delete(user)

         found = false
         @channels.each_value{|channelUsers|
            if (channelUsers.has_key?(user))
               found = true
               break
            end
         }

         if (!found)
            @users.delete(user)
         end

         Command.userLeft(self, channel, user, reason)
         logChat(user, channel, "** PART'd #{channel}. **")
      end
   end

   def handleStdinInput(command)
      command.strip!

      if (command.length() > 0)
         log(DEBUG, "Recieved command: #{command}")
         Command.invoke(ResponseInfo.new(self, CONSOLE, CONSOLE, CONSOLE_USER), command)
      end
   end

   # Check all channels
   def globalHasUser?(nick)
      return @users.has_key?(nick)
   end

   # Check only the current channel
   def channelHasUser?(nick, channel)
      return @channels[channel].has_key?(nick)
   end

   def getChannels()
      return @channels
   end

   def getUsers()
      return @users
   end

   def getUser(nick)
      return @users[nick]
   end

   def giveOps(user, channel)
      sendMessage("MODE #{channel} +o #{user}")
   end

   def takeOps(user, channel)
      sendMessage("MODE #{channel} -o #{user}")
   end

   # Inform  the bot that it should perform its periodic actions
   def periodicActions
   end

   def initEmailMap
      @emailMap.clear()

      res = dbQuery("SELECT nick, email, domain FROM #{NICK_MAP_TABLE}")
      if (res)
         res.each{|row|
            @emailMap[row[0]] = {:email => row[1], :domain => row[2]}
         }
      end
   end
end
