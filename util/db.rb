require './core/logging.rb'

require 'mysql'

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

   def query(queryStr)
      begin
         res = db.query(queryStr)
         return res
      rescue Exception => ex
         log(ERROR, ex.message)
         return nil
      end
      return nil
   end

   def update(statement)
      begin
         db.query(statement)
         return true
      rescue Exception => ex
         log(ERROR, ex.message)
         return false
      end
      return false
   end
end
