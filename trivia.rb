require 'mysql'

MYSQL_HOST = 'localhost'
MYSQL_USER = 'clefable'
MYSQL_PASS = 'KantoMtMoon'
MYSQL_DB = 'clefable_bot'

JOKES_TABLE = 'jokes'
FACTS_TABLE = 'facts'

class Trivia < Command
   def initialize
      super('TRIVIA',
            'TRIVIA [<fact number>]',
            'Get a fun fact. If no number is provided, a random one is picked.')
      @db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
   end

   @@instance = Trivia.new()

   def onCommand(server, channel, fromUser, args, onConsole)
      args.strip!
      if (args.match(/^\d+$/))
         res = @db.query("SELECT fact" + 
                         " FROM #{FACTS_TABLE}" +
                         " WHERE id = #{args}")
         if (!res || res.num_rows() == 0)
            server.chat(channel, "'#{args}' is not a valid fact number.")
         else
            server.chat(channel, "Fact ##{args}: #{res.fetch_row()[0]}")
         end
      else
         res = @db.query("SELECT id, fact" + 
                         " FROM #{FACTS_TABLE}" +
                         " ORDER BY RAND() LIMIT 1")
         row = res.fetch_row()
         server.chat(channel, "Fact ##{row[0]}: #{row[1]}")
      end
   end
end

class Joke < Command
   def initialize
      super('JOKE',
            'JOKE [<joke number>]',
            'Get a "funny" joke. If no number is provided, a random one is picked.')
      @db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
   end

   @@instance = Joke.new()

   def onCommand(server, channel, fromUser, args, onConsole)
      args.strip!
      if (args.match(/^\d+$/))
         res = @db.query("SELECT joke" + 
                         " FROM #{JOKES_TABLE}" +
                         " WHERE id = #{args}")
         if (!res || res.num_rows() == 0)
            server.chat(channel, "'#{args}' is not a valid joke number.")
         else
            server.chat(channel, "Joke ##{args}: #{res.fetch_row()[0]}")
         end
      else
         res = @db.query("SELECT id, joke" + 
                         " FROM #{JOKES_TABLE}" +
                         " ORDER BY RAND() LIMIT 1")
         row = res.fetch_row()
         server.chat(channel, "Joke ##{row[0]}: #{row[1]}")
      end
   end
end
