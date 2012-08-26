# The class is responsible for doing the select and all input.
# All input is passed to every InputHandler

require './core/thread/thread_wrapper.rb'

class InputThread < ThreadWrapper
   @@instance = nil

   def self.init(socket, lock)
      @@instance = InputThread.new(socket, lock)
   end

   def self.instance
      if (!@@instance)
         LOG(FATAL, 'InputThread was not init() before use.')
      end

      return @@instance
   end

   protected

   # The main listening loop
   # Listents on @socket and $stdin
   def run()
      #Keep track of time so the periodic things can be done
      lastTime = Time.now().to_i

      while (true)
         selectRes = IO.select([@socket, $stdin], nil, nil, SELECT_TIMEOUT)
         if (selectRes)
            # Check the read ios
            selectRes[0].each{|ioStream|
               if (ioStream.eof)
                  # Got an eof? Stop the thread
                  stop()
                  return
               end

               if (ioStream == @socket)
                  data = ''
                  @lock.synchronize{
                     data = @socket.gets()
                  }

                  InputHandler::queueTask(InputHandler::SERVER_INPUT, data)
               elsif (ioStream == $stdin)
                  InputHandler::queueTask(InputHandler::STDIN_INPUT, $stdin.gets())
               else
                  # Got some crazy io stream
                  log(ERROR, "Got bad io stream #{ioStream}")
               end
            }
         end

         now = Time.now().to_i
         if (now - lastTime >= SELECT_TIMEOUT)
            #Do periodic stuff
            lastTime = now
            InputHandler::queueTask(InputHandler::PERIODIC_ACTIONS, nil)
         end
      end
   end

   private

   def initialize(socket, lock)
      super()

      @socket = socket
      @lock = lock
   end
end
