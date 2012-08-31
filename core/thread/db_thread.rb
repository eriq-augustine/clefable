require './core/thread/worker_thread.rb'

# BD callbacks should be very quick.
class DBThread < WorkerThread
   include DB

   def queueQuery(query, callback = lambda{|param|})
      queueTask(lambda{return dbQuery(query)}, callback)
   end

   def queueUpdate(statement, callback = lambda{|param|})
      queueTask(lambda{return dbUpdate(statement)}, callback)
   end

   private

   def initialize()
      super()
   end
end
