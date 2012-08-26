# A basic wrapper around a Thread.

require 'thread'

# Children must implement: run().
# run() is the starting and re-entry point for the thread.
#  A thread that accidently throws an exception will be restarted on run().
class ThreadWrapper
   def start()
      @thread.wakeup
   end

   def stop()
      @die = true
      @thread.exit()
   end

   protected

   def initialize()
      @die = false
      @thread = Thread.new{
         while (!@die)
            Thread.stop
            begin
               run()
            rescue Interrupt
               @die = true
            rescue Exception => detail
               log(ERROR, (detail.message() + "\n" + detail.backtrace.join("\n")))
               retry
            end
         end
      }

      sleep(1)
   end
 
   # UNIMPLEMENTED
   def run()
      notreached('Unimplemented Method') 
   end
end
