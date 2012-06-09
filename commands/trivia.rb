class Trivia < Command
   include DB

   def initialize
      super('TRIVIA',
            'TRIVIA [<fact number>]',
            'Get a fun fact. If no number is provided, a random one is picked.')
   end

   @@instance = Trivia.new()

   def onCommand(responseInfo, args, onConsole)
      args.strip!
      if (args.match(/^\d+$/))
         res = db.query("SELECT fact" + 
                         " FROM #{FACTS_TABLE}" +
                         " WHERE id = #{args}")
         if (!res || res.num_rows() == 0)
            responseInfo.respond("'#{args}' is not a valid fact number.")
         else
            responseInfo.respond("Fact ##{args}: #{res.fetch_row()[0]}")
         end
      else
         res = db.query("SELECT id, fact" + 
                         " FROM #{FACTS_TABLE}" +
                         " ORDER BY RAND() LIMIT 1")
         row = res.fetch_row()
         responseInfo.respond("Fact ##{row[0]}: #{row[1]}")
      end
   end
end

class Joke < Command
   include DB

   def initialize
      super('JOKE',
            'JOKE [<joke number>]',
            'Get a "funny" joke. If no number is provided, a random one is picked.')
   end

   @@instance = Joke.new()

   def onCommand(responseInfo, args, onConsole)
      args.strip!
      if (args.match(/^\d+$/))
         res = db.query("SELECT joke" + 
                         " FROM #{JOKES_TABLE}" +
                         " WHERE id = #{args}")
         if (!res || res.num_rows() == 0)
            responseInfo.respond("'#{args}' is not a valid joke number.")
         else
            responseInfo.respond("Joke ##{args}: #{res.fetch_row()[0]}")
         end
      else
         res = db.query("SELECT id, joke" + 
                         " FROM #{JOKES_TABLE}" +
                         " ORDER BY RAND() LIMIT 1")
         row = res.fetch_row()
         responseInfo.respond("Joke ##{row[0]}: #{row[1]}")
      end
   end
end
