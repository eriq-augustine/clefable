# encoding: utf-8

require "socket"
require "mysql"

require './command_core.rb'
require './console_commands.rb'
require './dance.rb'

IRC_HOST = 'irc.freenode.net'
IRC_PORT = 6667
IRC_NICK = 'Clefable_BOT'
#IRC_CHANNEL = '#softwareinventions'
IRC_CHANNEL = '#eriq_secret'

USER_NAME = IRC_NICK
HOST_NAME = 'Mt.Moon'
SERVER_NAME = 'Kanto'
REAL_NAME = 'Clefable Bot'

MYSQL_HOST = 'localhost'
MYSQL_USER = 'clefable'
MYSQL_PASS = 'KantoMtMoon'
MYSQL_DB = 'clefable_bot'
LOG_TABLE = 'logs'

# TODO: Remove admin when ops is taken
class User
   attr_reader :nick, :isAdmin

   def initialize(nick, isAdmin)
      @nick = nick
      @isAdmin = isAdmin
   end
end

class IRCServer
   def initialize(hostName, port, nick, channelName)
      @hostName = hostName
      @port = port
      @nick = nick
      @channelName = channelName
      @ircSocket = nil
      @users = Hash.new()
      @db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
   end

   # Send to the IRC Server
   def sendMessage(message)
      puts "[INFO] Sending: #{message}"
      @ircSocket.send("#{message}\n", 0) 
   end

   # Connect to the host irc server and join @channel
   def connect()
      puts '[INFO] Connecting to server...'

      @ircSocket = TCPSocket.open(@hostName, @port)
      sendMessage("USER #{USER_NAME} 0 * :#{REAL_NAME}")
      sendMessage("NICK #{@nick}")
      sendMessage("JOIN #{@channelName}")

      puts "[INFO] Connected to #{@hostName}:#{@port}#{@channel} as #{@nick}"
   end

   def chat(message)
      sendMessage("PRIVMSG #{@channelName} :#{message}")
   end

   def handleServerInput(message)
      message.strip!
      puts "[INFO] Server says: #{message}"

      # PING :<server>
      if (match = message.match(/^PING\s:(.*)$/))
         sendMessage("PONG :#{match[1]}")
      # :<from user>!<from user>@<from address> PRIVMSG <to> :<message>
      # <to> is usually a channel
      elsif (match = message.match(/^:([^!]*)!([^@]*)@([^\s]*)\sPRIVMSG\s([^\s]*)\s:(.*)$/))
         if (commandMatch = match[5].strip.match(/^#{IRC_NICK}:\s*(.+)$/))
            Command.invoke(self, match[1], commandMatch[1])
         end
         log(match[1], match[5])
      # Recieving user names from the server
      # admin names are prepended with '@'
      # :<server> 353 <nick> @ <channel> :<user list (space seperated)>
      elsif (match = message.match(/^:(\S+)\s+353\s+(\S+)\s+@\s+(\S+)\s+:(.*)$/))
         users = match[4].split(/\s+/)

         users.each{|user|
            user.strip!
            admin = false

            if (user.start_with?('@'))
               admin = true
               user.sub!(/^@/, '')
            end

            if (!@users.has_key?(user))
               @users[user] = User.new(user, admin)
               Command.userPresentOnJoin(self, user)
            end
         }
      # :<from user>!<from user>@<from address> JOIN <channel>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sJOIN\s(\S*)$/))
         user = match[1]
         @users[user] = User.new(user, false)
         Command.userJoined(self, user)
      # :<from user>!<from user>@<from address> PART <channel> :<reason>
      elsif (match = message.match(/^:([^!]*)!([^@]*)@(\S*)\sPART\s(\S*)\s:(.*)$/))
         user = match[1]
         reason = match[5]

         @users.delete(user)
         Command.userLeft(self, user, reason)
      end
   end

   def handleStdinInput(command)
      command.strip!

      if (command.length() > 0)
         puts "[INFO] Recieved command: #{command}"
         Command.invoke(self, '_CONSOLE_', command, true)
      end
   end

   def hasUser?(nick)
      return @users.has_key?(nick)
   end

   def getUsers()
      return @users
   end

   def log(fromUser, message)
      @db.query("INSERT INTO #{LOG_TABLE} (timestamp, user, message)" + 
               " VALUES (#{Time.now().to_i()}, '#{fromUser}', '#{@db.escape_string(message)}')")
   end

   # The main listening loop
   # Listents on the @ircSocket and $stdin
   def listen()
      while (true)
         # TODO: Do it right so we can listen on $stdin and put in bg and such
         #  It may already be right, but just needs to be tested
         selectRes = select([@ircSocket, $stdin], nil, nil, nil)
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
      end
   end
end

irc = IRCServer.new(IRC_HOST, IRC_PORT, IRC_NICK, IRC_CHANNEL)
irc.connect()

#Request the user list now
irc.sendMessage("NAMES #{IRC_CHANNEL}")

begin
   irc.listen()
rescue Interrupt
   puts '[INFO] Recieved interrupt, server shutting down...'
rescue Exception => detail
   puts detail.message()
   print detail.backtrace.join("\n")
   retry
end
