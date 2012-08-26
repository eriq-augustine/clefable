require './core/thread/queue_thread.rb'

# All output to the server should go through this thread.
# This class will also handle the sleeping involved with flood control.
class OutputThread < QueueThread
   @@instance = nil

   def self.init(socket, lock)
      @@instance = OutputThread.new(socket, lock)
   end

   def self.instance
      if (!@@instance)
         LOG(FATAL, 'OutputThread was not init() before use.')
      end

      return @@instance
   end

   def queueMessage(message, delay = 0)
      queue({:message => message, :delay => delay})
   end

   protected

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

   # Send the message that was in the queue
   def processRecord(record)
      message = record[:message]
      delay = record[:delay]

      sleepTime = waitTime()

      if (delay > sleepTime)
         sleepTime = delay
      end

      @lock.synchronize{
        @socket.send("#{message}\n", 0)
      }

      sleep(sleepTime)
   end

   private

   def initialize(socket, lock)
      super()

      @socket = socket
      @lock = lock
      
      @floodControl = Hash.new(0)
      @lastFloodBucketReap = 0
   end
end
