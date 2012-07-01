# This class should only be new()'d once.
# If you need to relad it for some reason, use reload()
class Clefable
   include DB
   include TextStyle

   attr_reader :channels, :users, :rewriteRules, :floodControl, :lastFloodBucketReap, :commitFetcher

   def initialize()
      # { channelName => { userName => user } }
      @channels = Hash.new{|hash, key| hash[key] = Hash.new() }
      # { userName => user }
      @users = Hash.new()
   
      # { target => rewrite }
      @rewriteRules = getRewriteRules()

      @floodControl = Hash.new(0)
      @lastFloodBucketReap = 0

      @commitFetcher = CommitFetcher.new()
      # Do the first update quietly
      @commitFetcher.updateCommits()
   end

   # Get the amount of time to wait before putting out a new message.
   # Strategy:
   #  Get the current epoch minute
   #  Add up five most recent buckets
   #  Do math
   def waitTime()
      time = Time.now().to_i / 60
      
      # Cleanup once every ten minutes
      if (@lastFloodBucketReap != time && time % 10 == 0)
         @floodControl.delete_if{|key, val| key <= (time - 5) }
         @lastFloodBucketReap = time
      end

      @floodControl[time] += 1

      count = 0
      for i in 0...5
         count += (@floodControl[time - i] * (5 - i))
      end

      return 0.1 + (count * 0.0393)
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

      # TODO: Split better, so words are not broken.
      for i in 0..(message.length() / MAX_MESSAGE_LEN)
         sleepTime = waitTime()
         delay = options[:delay]
         if (delay)
            sleepTime = (sleepTime < delay) ? delay : sleepTime
         end

         part = message[i * MAX_MESSAGE_LEN, (i + 1) * MAX_MESSAGE_LEN]
         IRCServer.instance.sendMessage("PRIVMSG #{channel} :#{part}")
         sleep(sleepTime)
      end
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
      #puts "[INFO] Server says: #{message}"

      # PING :<server>
      if (match = message.match(/^PING\s:(.*)$/))
         IRCServer.instance.sendMessage("PONG :#{match[1]}")
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
            log(fromUser, target, content)
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
      # :<from user>!<from user>@<from address> JOIN <channel>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sJOIN\s(\S*)$/))
         user = match[1]
         channel = match[4]
         ensureUser(user, channel, false)
         Command.userJoined(self, channel, user)
      # Clefable PART'ed
      # :Clefable_BOT!<something like ~Clefable_>@<from address> PART <channel>
      elsif (match = message.match(/^:#{IRC_NICK}!([^@]*)@(\S*)\sPART\s(\S*)\s*$/))
         channel = match[3]
         @channels.delete(channel)
      # :eriq_home!~eriq_home@c-50-131-15-127.hsd1.ca.comcast.net QUIT :Quit: Leaving
      # :<from user>!<from user>@<from address> QUIT :<reason>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sQUIT\s+:(.*)$/))
         user = match[1]
         channel = match[4]
         reason = match[5]

         @users.delete(user)
         @channels.each_value{|users|
            users.delete(user)
            Command.userLeft(self, channel, user, reason)
         }
      # :<from user>!<from user>@<from address> PART <channel> :<reason>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sPART\s(\S*)\s:(.*)$/))
         user = match[1]
         channel = match[4]
         reason = match[5]

         @channels[channel].delete(user)

         found = false
         @channels.each_value{|users|
            if (users.has_key?(user))
               found = true
               break
            end
         }

         if (!found)
            @users.delete(user)
         end

         Command.userLeft(self, channel, user, reason)
      end
   end

   def handleStdinInput(command)
      command.strip!

      if (command.length() > 0)
         #puts "[INFO] Recieved command: #{command}"
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

   def giveOps(user, channel)
      IRCServer.instance.sendMessage("MODE #{channel} +o #{user}")
   end

   def takeOps(user, channel)
      IRCServer.instance.sendMessage("MODE #{channel} -o #{user}")
   end

   def log(fromUser, toUser, message)
      db.query("INSERT INTO #{LOG_TABLE} (timestamp, `to`, `from`, message)" + 
               " VALUES (#{Time.now().to_i()}, '#{toUser}', '#{fromUser}', '#{db.escape_string(message)}')")
   end

   # Inform Clefable that she should perform its periodic actions
   def periodicActions
      # Check for new commits
      newCommits = @commitFetcher.updateCommits()
      if (!newCommits.empty?)
         #Check all the channels for the committers
         notifyAboutCommits(newCommits)
      end
   end

   def notifyAboutCommits(newCommits)
      newCommits.each{|commit|
         committer = commit[:author].sub(/@.*$/, '')

         @channels.each_pair{|channel, users|
            broadcast = false
            users.each_key{|nick|
               #It is common practice to append '_' or '-' to your nick if it is taken.
               realNick = nick.sub(/[_-]+$/, '')
               # TODO: Use the registered emails instead of or in addition to the map
               if (committer == realNick || EMAIL_MAP[realNick] == committer)
                  broadcast = true
                  break
               end
            }

            if (broadcast)
               chat(channel, "#{purple("http://crrev.com/#{commit[:rev]}")}" +
                             " ^#{commit[:author]} -- #{commit[:summary]}")
            end
         }
      }
   end

   def set(channels, users, rewriteRules, floodControl, lastFloodBucketReap, commitFetcher)
      @channels = channels
      @users = users
      @rewriteRules = rewriteRules
      @floodControl = floodControl
      @lastFloodBucketReap = lastFloodBucketReap
      @commitFetcher = commitFetcher
   end

   def self.instance
      if (!@@instance)
         @@instance = Clefable.new()
      end

      return @@instance
   end

   def self.reload
      @@insatnce = reinit()
   end

   # These lines allows Clefable to be dynamically reloaded without losing state.
   def self.reinit()
      if (!defined?(@@instance) || !@@instance)
         return nil
      end

      newClef = Clefable.new()
      newClef.set(@@instance.channels, @@instance.users,
                  @@instance.rewriteRules, @@instance.floodControl,
                  @@instance.lastFloodBucketReap, @@instance.commitFetcher)

      return newClef
   end
   
   @@instance = reinit()
end
