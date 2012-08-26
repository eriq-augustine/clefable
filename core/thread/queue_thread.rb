require './core/thread/thread_wrapper.rb'

# A wrapper around a thread that provides queuing semantics.
# Child classes need to provide the functionality for dealing with a dequeued record.
class QueueThread < ThreadWrapper
   def killQueue
      @queueLock.synchronize{
         @queue.clear()
         if (@thread.stop?)
            @thread.wakeup
         end
      }
   end

   protected

   def initialize()
      super()

      @queue = Array.new()
      @queueLock = Mutex.new()
   end
 
   def queue(record)
      @queueLock.synchronize{
         @queue << record
         if (@thread.stop?)
            @thread.wakeup
         end
      }
   end

   # empty the queue
   def run()
      done = false
      while (!done)
         record = nil
         @queueLock.synchronize{
            record = @queue.shift
            if (!record)
               done = true
            end
         }

         if (!done)
            processRecord(record)
         end
      end
   end

   # UNIMPLEMENTED
   def processRecord(record)
      notreached('Unimplemented Method')
   end
end
