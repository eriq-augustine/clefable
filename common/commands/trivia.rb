class Trivia < Command
   include DB

   def initialize
      super('TRIVIA',
            'TRIVIA [<fact number>]',
            'Get a fun fact. If no number is provided, a random one is picked.')
   end

   @@instance = Trivia.new()

   def onCommand(responseInfo, args)
      args.strip!
      if (args.match(/^\d+$/))
         res = dbQuery("SELECT fact" + 
                       " FROM #{FACTS_TABLE}" +
                       " WHERE id = #{args}")
         if (!res || res.num_rows() == 0)
            responseInfo.respond("'#{args}' is not a valid fact number.")
         else
            responseInfo.respond("Fact ##{args}: #{res.fetch_row()[0]}")
         end
      else
         res = dbQuery("SELECT id, fact" + 
                       " FROM #{FACTS_TABLE}" +
                       " ORDER BY RAND() LIMIT 1")
         row = res.fetch_row()
         responseInfo.respond("Fact ##{row[0]}: #{row[1]}")
      end
   end
end
