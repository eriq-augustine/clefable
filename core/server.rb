# STOP: Before you add code to Server, remember that the server
#  cannot be properly reloaded at runtime. Clefable will have to be
#  entirely reboted to reload server code. So try and put it somewhere else.

class Server
   def initialize(hostName, port, nick)
      @hostName = hostName
      @port = port
      @nick = nick
      @ircSocket = nil
      @lock = nil
   end

   def start()
      log(INFO, 'Connecting to server...')

      @lock = Mutex.new()
      @ircSocket = TCPSocket.open(@hostName, @port)

      InputThread.init(@ircSocket, @lock)
      OutputThread.init(@ircSocket, @lock)

      DBThread.instance()

      InputThread.instance.start()

      OutputThread.instance.queueMessage("USER #{IRC_NICK} 0 * :#{REAL_NAME}", 0)
      OutputThread.instance.queueMessage("NICK #{@nick}", 0)

      log(INFO, "Connected to #{@hostName}:#{@port} as #{@nick}")
   end
end
