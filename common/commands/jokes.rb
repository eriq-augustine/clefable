class Joke < Command
   include DB

   def initialize
      super('JOKE',
            'JOKE [<joke number>]',
            'Get a "funny" joke. If no number is provided, a random one is picked.')
   end

   @@instance = Joke.new()

   def onCommand(responseInfo, args)
      args.strip!
      if (args.match(/^\d+$/))
         res = dbQuery("SELECT joke" +
                       " FROM #{JOKES_TABLE}" +
                       " WHERE id = #{args}")
         if (!res || res.num_rows() == 0)
            responseInfo.respond("'#{args}' is not a valid joke number.")
         else
            responseInfo.respond("Joke ##{args}: #{res.fetch_row()[0]}")
         end
      else
         res = dbQuery("SELECT id, joke" +
                       " FROM #{JOKES_TABLE}" +
                       " ORDER BY RAND() LIMIT 1")
         row = res.fetch_row()
         responseInfo.respond("Joke ##{row[0]}: #{row[1]}")
      end
   end
end
