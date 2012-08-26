require 'mysql'

# Callbacks (lambda) should not do any mutations.

# Reopen the DB module
module DB
   def escape(str)
      return Mysql::escape_string(str)
   end

   def getRewriteRules()
      rtn = Hash.new()

      res = mysqlDb.query("SELECT target, rewrite FROM #{REWRITE_TABLE}")

      if (res)
         res.each{|row|
            rtn[row[0]] = row[1]
         }
      end

      return rtn
   end

   # If present, |callback| will even be invoked if |async| is false.
   def dbQuery(queryStr, async = false, callback = lambda{|param|})
      if (async)
         DBThread::instance().queueQuery(queryStr, callback)
      else
         rtn = nil

         begin
            res = mysqlDb.query(queryStr)
            rtn = res
         rescue Exception => ex
            log(ERROR, ex.message)
         end

         callback.call(rtn)

         return rtn
      end
   end

   # If present, |callback| will even be invoked if |async| is false.
   def dbUpdate(statement, async = false, callback = lambda{|param|})
      if (async)
         DBThread::instance().queueUpdate(statement, callback)
      else
         rtn = false

         begin
            mysqlDb.query(statement)
            rtn = true
         rescue Exception => ex
            log(ERROR, ex.message)
         end

         callback.call(rtn)

         return rtn
      end
   end

   def dbInsertId()
      return mysqlDb.insert_id()
   end

   # Chat logs needs to be done specially because they are so common.
   # Without this, every chat would generate an insert.
   # These inserts needs to be aggregated into a single number if inserts.
   # (Actually, not necessarily a single insert, but a condensed amount)
   # TODO(eriq): This is a slight race condition with @@chatInQueue.
   #  It is pretty minor and only causes a (few?) logs to get missed until the next update.
   def logChat(fromUser, toUser, message)
      @@chatLock.synchronize{
         @@chatLogs << {:fromUser => fromUser, :toUser => toUser,
                        :message => message, :timestamp => Time.now().to_i()}
      }

      if (!@@chatInQueue)
         # Queue up the task
         DBThread::instance().queueTask(lambda{emptyChatQueue()})
         @@chatInQueue = true
         return
      end
   end

   private

   def emptyChatQueue()
      chats = nil
      @@chatLock.synchronize{
         chats = @@chatLogs.pop(QUERY_AGGREGATE_MAX)
      }

      while (chats.size() > 0)
         insert = "INSERT INTO #{LOG_TABLE} (timestamp, `to`, `from`, message) VALUES "

         chats.each{|chat|
            insert += "(#{chat[:timestamp]}, '#{chat[:toUser]}', '#{chat[:fromUser]}', '#{escape(chat[:message])}'), "
         }
         insert.sub!(/, $/, '')

         dbUpdate(insert)

         @@chatLock.synchronize{
            chats = @@chatLogs.pop(QUERY_AGGREGATE_MAX)
         }
      end

      @@chatInQueue = false
   end

   def mysqlDb
      if (!defined?(@mysqlDb) || !@mysqlDb || @mysqlDb.nil?)
         @mysqlDb = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
         @mysqlDb.reconnect = true
      end

      return @mysqlDb
   end

   @@chatLogs = Array.new()
   @@chatInQueue = false
   @@chatLock = Mutex.new()
end
