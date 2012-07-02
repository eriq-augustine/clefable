# STOP: Before you add code to Server, remember that the server
#  cannot be properly reloaded at runtime. Clefable will have to be 
#  entirely reboted to reload server code. So try and put it somewhere else.

require 'socket'
require 'thread'

class InputServer
   @@thread = nil
   @@die = false

   def self.init(socket, lock)
      @@socket = socket
      @@lock = lock

      @@die = false
      @@thread = Thread.new{
         while (!@@die)
            Thread.stop
            begin
               listen()
            rescue Interrupt
               @@die = true
            rescue Exception => detail
               puts detail.message()
               print detail.backtrace.join("\n")
               retry
            end
         end
      }

      #TEST
      sleep(1)
   end
   
   def self.start()
      @@thread.wakeup
   end

   def self.stop
      @@die = true
      @@thread.exit()
   end

   private

   # The main listening loop
   # Listents on @socket and $stdin
   def self.listen()
      #Keep track of time so the periodic things can be done
      lastTime = Time.now().to_i

      while (true)
         # TODO: Do it right so we can listen on $stdin and put in bg and such
         #  It may already be right, but just needs to be tested
         selectRes = IO.select([@@socket, $stdin], nil, nil, SELECT_TIMEOUT)
         if (selectRes)
            # Check the read ios
            selectRes[0].each{|ioStream|
               if (ioStream.eof)
                  # Got an eof? Stop the server
                  return
               end

               if (ioStream == @@socket)
                  data = ''
                  @@lock.synchronize{
                     data = @@socket.gets()
                  }
                  ClefableThread.queueTask(ClefableThread::SERVER_INPUT, data)
               elsif (ioStream == $stdin)
                  ClefableThread.queueTask(ClefableThread::STDIN_INPUT, $stdin.gets())
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
            ClefableThread.queueTask(ClefableThread::PERIODIC_ACTIONS, nil)
         end
      end
   end
end

class OutputServer
   @@socket = nil
   @@lock = nil

   @@queueLock = nil
   @@queue = nil

   @@thread = nil
   @@die = false

   def self.init(socket, lock)
      @@socket = socket
      @@lock = lock
      
      @@queue = Array.new()
      @@queueLock = Mutex.new()
      
      @@die = false
      @@thread = Thread.new{
         while (!@@die)
            Thread.stop

            begin
               emptyQueue()
            rescue Interrupt
               @@die = true
            rescue Exception => detail
               puts detail.message()
               print detail.backtrace.join("\n")
               retry
            end
         end
      }

      @@floodControl = Hash.new(0)
      @@lastFloodBucketReap = 0

      #TEST
      sleep(1)
   end
   
   def self.stop()
      @@die = true
      @@thread.exit
   end

   def self.killQueue
      @@queueLock.synchronize{
         @@queue.clear()
      }
   end

   def self.queueMessage(message, delay = 0)
      @@queueLock.synchronize{
         @@queue << {:message => message, :delay => delay}
         if (@@thread.stop?)
            @@thread.wakeup
         end
      }
   end

   private

   # Get the amount of time to wait before putting out a new message.
   # Strategy:
   #  Get the current epoch minute
   #  Add up five most recent buckets
   #  Do math
   def self.waitTime()
      time = Time.now().to_i / 60

      # Cleanup once every ten minutes
      if (@@lastFloodBucketReap != time && time % 10 == 0)
         @@floodControl.delete_if{|key, val| key <= (time - 5) }
         @@lastFloodBucketReap = time
      end

      @@floodControl[time] += 1

      count = 0
      for i in 0...5
         count += (@@floodControl[time - i] * (5 - i))
      end

      return 0.1 + (count * 0.0393)
   end

   def self.emptyQueue()
      done = false
      while (!done)
         message = ''
         delay = 0
         @@queueLock.synchronize{
            info = @@queue.shift
            if (!info)
               done = true
            else
               message = info[:message]
               delay = info[:delay]
            end
         }

         if (!done)
            sendMessage(message, delay)
         end
      end
   end

   # Send to the IRC Server
   def self.sendMessage(message, delay)
      sleepTime = waitTime()

      if (delay > sleepTime)
         sleepTime = delay
      end

      @@lock.synchronize{
        @@socket.send("#{message}\n", 0) 
      }

      sleep(sleepTime)
   end
end

class Server
   def initialize(hostName, port, nick)
      @hostName = hostName
      @port = port
      @nick = nick
      @ircSocket = nil
      @lock = nil
   end
   
   def start()
      puts '[INFO] Connecting to server...'
      
      @lock = Mutex.new()
      @ircSocket = TCPSocket.open(@hostName, @port)
      
      InputServer.init(@ircSocket, @lock)
      OutputServer.init(@ircSocket, @lock)

      InputServer.start()
      
      OutputServer.queueMessage("USER #{USER_NAME} 0 * :#{REAL_NAME}", 0)
      OutputServer.queueMessage("NICK #{@nick}", 0)
      
      puts "[INFO] Connected to #{@hostName}:#{@port} as #{@nick}"
   end
end
