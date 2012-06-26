# STOP: Before you add code to Server, remember that the server
#  cannot be properly reloaded at runtime. Clefable will have to be 
#  entirely reboted to reload server code. So try and put it somewhere else.

require 'socket'

class IRCServer
   attr_accessor :ircSocket

   def initialize(hostName, port, nick)
      @hostName = hostName
      @port = port
      @nick = nick
      @ircSocket = nil
   end
   
   # Connect to the host irc server
   def connect()
      puts '[INFO] Connecting to server...'

      @ircSocket = TCPSocket.open(@hostName, @port)
      sendMessage("USER #{USER_NAME} 0 * :#{REAL_NAME}")
      sendMessage("NICK #{@nick}")

      puts "[INFO] Connected to #{@hostName}:#{@port} as #{@nick}"
   end

   # Send to the IRC Server
   def sendMessage(message)
      #puts "[INFO] Sending: #{message}"
      @ircSocket.send("#{message}\n", 0) 
   end

   def join(channel)
      sendMessage("JOIN #{channel}")
      puts "[INFO] Joined #{channel}"
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
                  Clefable.instance.handleServerInput(@ircSocket.gets())
               elsif (ioStream == $stdin)
                  Clefable.instance.handleStdinInput($stdin.gets())
               else
                  # Got some crazy io stream
                  puts "[ERROR] Got bad io stream #{ioStream}"
               end
            }
         end

         now = Time.now().to_i
         if (now - lastTime >= SELECT_TIMEOUT)
            #Do periodic stuff
            lastTime = now
            Clefable.instance.periodicActions()
         end
      end
   end

   def self.init(host, port, nick)
      @@host = host
      @@port = port
      @@nick = nick
   end

   def self.instance
      if (!@@instance)
         @@instance = IRCServer.new(@@host, @@port, @@nick)
      end

      return @@instance
   end

   def self.reinit()
      if (!defined?(@@instance) || !@@instance)
         return nil
      end

      newServer = IRCServer.new(@@host, @@port, @@nick)
      newServer.socket(@@instance.socket)

      return newServer
   end

   @@instance = reinit()
end
