# encoding: utf-8

# TODO: Deal with QUIT

require 'socket'

require './command_core.rb'
require './users.rb'

IRC_HOST = 'irc.freenode.net'
IRC_PORT = 6667
IRC_NICK = 'Clefable_BOT'

#Wait for 2 mins on select
SELECT_TIMEOUT = 120

DEFAULT_CHANNELS = ['#eriq_secret', '#bestfriendsclub']
#DEFAULT_CHANNELS = ['#eriq_secret']
#DEFAULT_CHANNELS = ['#crx', '#eriq_secret', '#bestfriendsclub', '#softwareinventions']
#DEFAULT_CHANNELS = ['#eriq_secret', '#bestfriendsclub', '#softwareinventions']

MAX_MESSAGE_LEN = 400

CONSOLE = '_CONSOLE_'
CONSOLE_USER = User.new(CONSOLE, false)
# TODO: Maybe don't give console user free reign
CONSOLE_USER.auth
CONSOLE_USER.setAdmin(0)

COMMAND_DIR = './commands'
UTIL_DIR = './util'

USER_NAME = IRC_NICK
SHORT_NICK = 'CLEF'
TRIGGER = '`'
HOST_NAME = 'Mt.Moon'
SERVER_NAME = 'Kanto'
REAL_NAME = 'Clefable Bot'

#Most people use their email as their username, but thses people don't.
EMAIL_MAP = {'eriq' => 'eaugusti', 'eriq_home' => 'eaugusti', 'aboodman' => 'aa', 'dcronin' => 'rdevlin.cronin'}

# Load all the utilities
Dir["#{UTIL_DIR}/*.rb"].each{|file|
   require file
}

# Load all the commands from COMMAND_DIR
Dir["#{COMMAND_DIR}/*.rb"].each{|file|
   require file
}

class IRCServer
   include DB

   attr_reader :rewriteRules

   def initialize(hostName, port, nick)
      @hostName = hostName
      @port = port
      @nick = nick
      @ircSocket = nil

      # { channelName => { userName => user } }
      @channels = Hash.new{|hash, key| hash[key] = Hash.new() }
      # { userName => user }
      @users = Hash.new()
   
      # { target => rewrite }
      @rewriteRules = getRewriteRules()

      @floodControl = Hash.new(0)

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
      
      # Cleanup every ten minutes
      if (time % 10 == 0)
         @floodControl.delete_if{|key, val|
            yield (key <= time - 5)
         }
      end

      @floodControl[time] += 1

      count = 0
      for i in 0...5
         count += (@floodControl[time - i] * (5 - i))
      end

      return 0.1 + (count * 0.0393)
   end

   # Send to the IRC Server
   def sendMessage(message)
      #puts "[INFO] Sending: #{message}"
      @ircSocket.send("#{message}\n", 0) 
   end

   # Connect to the host irc server
   def connect()
      puts '[INFO] Connecting to server...'

      @ircSocket = TCPSocket.open(@hostName, @port)
      sendMessage("USER #{USER_NAME} 0 * :#{REAL_NAME}")
      sendMessage("NICK #{@nick}")

      puts "[INFO] Connected to #{@hostName}:#{@port} as #{@nick}"
   end

   def join(channel)
      sendMessage("JOIN #{channel}")
      puts "[INFO] Joined #{channel}"
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
         sendMessage("PRIVMSG #{channel} :#{part}")
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
      # TODO: Deal with QUIT
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
      sendMessage("MODE #{channel} +o #{user}")
   end

   def takeOps(user, channel)
      sendMessage("MODE #{channel} -o #{user}")
   end

   def log(fromUser, toUser, message)
      db.query("INSERT INTO #{LOG_TABLE} (timestamp, `to`, `from`, message)" + 
               " VALUES (#{Time.now().to_i()}, '#{toUser}', '#{fromUser}', '#{db.escape_string(message)}')")
   end

   # The main listening loop
   # Listents on the @ircSocket and $stdin
   def listen()
      #Keep track of time so the periodic things can be done
      lastTime = Time.now().to_i

      while (true)
         # TODO: Do it right so we can listen on $stdin and put in bg and such
         #  It may already be right, but just needs to be tested
         selectRes = IO.select([@ircSocket, $stdin], nil, nil, SELECT_TIMEOUT)
         if (selectRes)
            # Check the read ios
            selectRes[0].each{|ioStream|
               if (ioStream.eof)
                  # Got an eof? Stop the server
                  return
               end

               if (ioStream == @ircSocket)
                  handleServerInput(@ircSocket.gets())
               elsif (ioStream == $stdin)
                  handleStdinInput($stdin.gets())
               else
                  # Got some crazy io stream
                  puts "[ERROR] Got bad io stream #{ioStream}"
               end
            }
         end

         now = Time.now().to_i
         if (now - lastTime >= SELECT_TIMEOUT)
            #Do periodic stuff
            newCommits = @commitFetcher.updateCommits()
            if (!newCommits.empty?)
               #Check all the channels for the committers
               notifyAboutCommits(newCommits)
            end
         end
      end
   end

   def notifyAboutCommits(newCommits)
      newCommits.each{|commit|
         committer = commit[:author].sub(/@.*$/, '')

         @channels.each_pair{|channel, users|
            broadcast = false
            users.each{|user|
               #It is common practice to append '_' to your nick if it is taken.
               nick = user.nick.sub(/_+$/, '')
               if (committer == nick || EMAIL_MAP[nick] == committer)
                  broadcast = true
                  break
               end
            }

            if (broadcast)
               chat(channel, "Rev: #{commit[:rev]} (#{Time.at(commit[:time])})" +
                             " ^#{commit[:author]} -- #{commit[:summary]}")
            end
         }
      }
   end
end

irc = IRCServer.new(IRC_HOST, IRC_PORT, IRC_NICK)
irc.connect()

#Request the user list now
DEFAULT_CHANNELS.each{|channel|
   irc.join(channel)
   irc.sendMessage("NAMES #{channel}")
}

begin
   irc.listen()
rescue Interrupt
   puts '[INFO] Recieved interrupt, server shutting down...'
rescue Exception => detail
   puts detail.message()
   print detail.backtrace.join("\n")
   retry
end
