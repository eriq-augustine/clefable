# The base bot behavior.
class Bot
   include DB
   include TextSplit
   include Levenshtein
   include Singleton

 public

   attr_reader :channels, :users, :rewriteRules, :emailMap

   def handleServerInput(message)
      message.strip!
      log(DEBUG, "Server says: #{message}")

      # PING :<server>
      if (match = message.match(/^PING\s:(.*)$/))
         sendMessage("PONG :#{match[1]}")
      # :<from user>!<from user>@<from address> PRIVMSG <to> :<message>
      # <to> is usually a channel
      elsif (match = message.match(/^:([^!]*)!([^@]*)@([^\s]*)\sPRIVMSG\s([^\s]*)\s:(.*)$/))
         handlePrivmsg(message, match[1], match[4], match[5].strip)
      # Recieving user names from the server
      # ones with ops names are prepended with '@'
      # :<server> 353 <nick> @ <channel> :<user list (space seperated)>
      elsif (match = message.match(/^:(\S+)\s+353\s+(\S+)\s+@\s+(\S+)\s+:(.*)$/))
         handleNickList(message, match[4].split(/\s+/), match[3])
      # :pratchett.freenode.net 311 TEST_BOT eriq_home ~eriq_home c-50-131-15-127.hsd1.ca.comcast.net * :eaugusti@chromium.org
      # :<requester irc server> 311 <requester name> <target user> ~<target nick (again?)> <address> * :<extra user info>
      elsif (match = message.match(/^:(\S+)\s+311\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+\*\s+:(.*)$/))
         handleWhois(message, match[3], match[5], match[6])
      # :<from user>!<from user>@<from address> JOIN <channel>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sJOIN\s(\S*)$/))
         handleUserJoin(message, match[1], match[4])
      # The bot PART'ed
      # :#{IRC_NICK}!<something like ~#{part of name}_>@<from address> PART <channel>
      elsif (match = message.match(/^:#{IRC_NICK}!([^@]*)@(\S*)\sPART\s(\S*)\s*$/))
         handlePart(message, match[3])
      # :eriq_home!~eriq_home@c-50-131-15-127.hsd1.ca.comcast.net QUIT :Quit: Leaving
      # :<from user>!<from user>@<from address> QUIT :<reason>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sQUIT\s+:(.*)$/))
         handleUserQuit(message, match[1], match[4])
      # :eriq!~eriq@c-50-131-15-127.hsd1.ca.comcast.net PART #eriq_secret
      # :eriq!~eriq@c-50-131-15-127.hsd1.ca.comcast.net PART #eriq_secret :"Leaving"
      # :<from user>!<from user>@<from address> PART <channel>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sPART\s(\S*)/))
         handleUserPart(message, match[1], match[4], match[5])
      end
   end

   # Available options:
   #  :rewrite: whether to invoke the rewrite engine (default: true)
   #  :delay: ensure a delay of at least this much, may be more because of flood control (default: 0)
   def chat(channel, message, options = {})
      # This is the last reasonable place that taking to yourself can be detected.
      if (channel == IRC_NICK)
         log(ERROR, "Attempt to send message to self: #{message}.")
         return
      end

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

   def handleStdinInput(command)
      command.strip!

      if (command.length() > 0)
         log(DEBUG, "Recieved command: #{command}")
         Command.invoke(ResponseInfo.new(self, CONSOLE, CONSOLE, CONSOLE_USER), command)
      end
   end

   def join(channel)
      sendMessage("JOIN #{channel}")
      log(INFO, "Joined #{channel}")
   end

   def whois(nick)
      sendMessage("WHOIS #{nick}")
   end

   # Register a lambda (with no parameters) as an action during periodic actions.
   def registerPeriodicAction(callback)
      @periodicActions << callback
   end

   # Inform  the bot that it should perform its periodic actions
   def periodicActions
      @periodicActions.each{|action|
         action.call()
      }
   end

 protected

   def initialize()
      # { channelName => { userName => user } }
      @channels = Hash.new{|hash, key| hash[key] = Hash.new() }

      # { userName => user }
      @users = Hash.new()

      # { target => rewrite }
      @rewriteRules = getRewriteRules()

      @emailMap = Hash.new()
      initEmailMap()
      
      @periodicActions = Array.new()
   end

   # Wrapper for InputQueue.queueMessage()
   def sendMessage(message, delay = 0)
      OutputThread.instance.queueMessage(message, delay)
   end

 private

   def ensureUser(user, channel, ops)
      if (!@users.has_key?(user))
         userInfo = User.new(user, ops)
         @users[user] = userInfo
         @channels[channel][user] = userInfo
      elsif (!@channels[channel].has_key?(user))
         @channels[channel][user] = @users[user]
      end
   end

   def handlePrivmsg(fullMessage, fromUser, target, content)
      responseInfo = ResponseInfo.new(self, fromUser, target, @users[fromUser])
      logMessage = true
      command = nil

      # Log, but do not respond to messages from self.
      if (fromUser == IRC_NICK)
         logMessage = true
      # If sent message is started with "#{IRC_NICK}:" or "#{SHORT_NICK}:" or "#{TRIGGER}"
      elsif (commandMatch = content.strip.match(/^((?:#{IRC_NICK}:)|(?:#{SHORT_NICK}:)|(?:#{TRIGGER}))\s*(.+)$/i))
         command = commandMatch[2]
      # If message was sent in a PM
      elsif (target == IRC_NICK)
         command = content
      # If it looks like a ping, but the target of the ping is not in the room.
      elsif (pingMatch = content.match(/^\^?([^\s\^]+)\^?:(\s+.*)?$/))
         # Note, we cannot be in a PM because of the previous case.
         pingTarget = pingMatch[1]

         # If channel exists, but the ping target does not, maybe they mistyped.
         if (@channels.has_key?(target) && !@channels[target][pingTarget])
            minInfo = minDistanceNoEquals(pingTarget, @channels[target].keys)

            if (minInfo && minInfo[:dist] <= MAX_PING_CORRECTION_DISTANCE)
               chat(target, "Automatic Ping Correction -- #{minInfo[:word]}: ^")
            end
         end
      end

      if (command)
         # This can happen at the beginning before all users are loaded.
         if (@users[fromUser])
            if (@users[fromUser].canExecute?())
               logMessage = Command.invoke(responseInfo, command)
            else
               # We are skipping this invocation, but we still may need to log.
               logMessage = !Command::skipLog?(content)
            end
         end
      end

      if (logMessage)
         logChat(fromUser, target, content)
      end
   end

   # This list usually comes from a 353.
   # A 353 is an indication that the server is sending nicks.
   def handleNickList(fullMessage, nicks, channel)
      nicks.each{|nick|
         nick.strip!
         ops = false

         if (nick.start_with?('@'))
            ops = true
            nick.sub!(/^@/, '')
         end

         ensureUser(nick, channel, ops)
      }
   end

   def handleWhois(fullMessage, user, address, extraInfo)
      if (@users[user])
         @users[user].address = address
         @users[user].extraInfo = extraInfo
         Command.userInfo(user, 'WHOIS', nil)
      else
         log(WARN, "Got userinfo on an unknown user: #{user}.")
      end
   end

   def handleUserJoin(fullMessage, user, channel)
      ensureUser(user, channel, false)
      Command.userJoined(self, channel, user)
      logChat(user, channel, "** JOIN'd #{channel} **")
   end

   # This is the bot parting, not a specific user.
   def handlePart(fullMessage, channel)
      @channels.delete(channel)
      logChat(IRC_NICK, channel, "** PART'd #{channel} **")
   end

   def handleUserQuit(fullMessage, user, reason)
      @users.delete(user)
      @channels.each_value{|channelUsers|
         channelUsers.delete(user)
         Command.userLeft(self, ALL_CHANNELS, user, reason)
      }

      logChat(user, ALL_CHANNELS, "** QUIT'd Resson: #{reason} **")
   end

   def handleUserPart(fullMessage, user, channel, reason)
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
