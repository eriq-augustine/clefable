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

   def db
      if (@db.nil?)
         @db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
      end
      
      return @db
   end

   def escape(str)
      return Mysql::escape_string(str)
   end
end
