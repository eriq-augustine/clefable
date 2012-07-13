require 'mysql'

module DB
   MYSQL_HOST = 'localhost'
   MYSQL_USER = 'clefable'
   MYSQL_PASS = 'KantoMtMoon'
   MYSQL_DB = 'clefable_bot'

   LOG_TABLE = 'logs'
   DANCE_TABLE = 'dances'
   JOKES_TABLE = 'jokes'
   FACTS_TABLE = 'facts'
   USERS_TABLE = 'users'
   NOTES_TABLE = 'notes'
   NOTE_TAGS_TABLE = 'note_tags'
   MESSAGES_TABLE = 'messages'
   REWRITE_TABLE = 'rewrite_rules'
   GLOSSARY_TABLE = 'glossary'
   COMMIT_TABLE = 'commits'
   EMAIL_TABLE = 'pending_emails'
   NICK_MAP_TABLE = 'nick_map'

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
         puts ex.message
         return nil
      end
      return nil
   end

   def update(statement)
      begin
         db.query(statement)
         return true
      rescue Exception => ex
         puts ex.message
         return false
      end
      return false
   end


end
