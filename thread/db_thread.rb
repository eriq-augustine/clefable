require './core/logging.rb'
require './thread/worker_thread.rb'
require './util/db.rb'

# BD callbacks should be very quick.
class DBThread < WorkerThread
   include DB

   @@instance = nil

   def self.init()
      @@instance = DBThread.new()
   end

   def self.instance
      if (!@@instance)
         LOG(FATAL, 'DBThread was not init() before use.')
      end

      return @@instance
   end

   def queueQuery(query, callback = lambda{|param|})
      queueTask(lambda{return query(query)}, callback)
   end

   def queueUpdate(statement, callback = lambda{|param|})
      queueTask(lambda{return update(statement)}, callback)
   end

   private
   
   def initialize()
      super()
   end
end
