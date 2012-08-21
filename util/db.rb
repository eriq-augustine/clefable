require './core/logging.rb'
require './thread/db_thread.rb'

require 'mysql'

# Callbacks (lambda) should not do any mutations.

# Reopen the DB module
module DB
   def db
      if (!@db || @db.nil?)
         @db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
         @db.reconnect = true
      end
      
      return @db
   end

   def escape(str)
      return Mysql::escape_string(str)
   end

   def getRewriteRules()
      rtn = Hash.new()

      res = db.query("SELECT target, rewrite FROM #{REWRITE_TABLE}")

      if (res)
         res.each{|row|
            rtn[row[0]] = row[1]
         }
      end

      return rtn
   end

   # If present, |callback| will even be invoked if |async| is false.
   def query(queryStr, async = false, callback = lambda{|param|})
      if (async)
         DBThread::instance().queueQuery(queryStr, callback)
      else
         rtn = nil

         begin
            res = db.query(queryStr)
            rtn = res
         rescue Exception => ex
            log(ERROR, ex.message)
         end
         
         callback.call(rtn)
         
         return rtn
      end
   end

   # If present, |callback| will even be invoked if |async| is false.
   def update(statement, async = false, callback = lambda{|param|})
      if (async)
         DBThread::instance().queueUpdate(statement, callback)
      else
         rtn = false

         begin
            db.query(statement)
            rtn = true
         rescue Exception => ex
            log(ERROR, ex.message)
         end

         callback.call(rtn)
   
         return rtn
      end
   end
end
