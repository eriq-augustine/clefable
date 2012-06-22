class Joke < Command
   include DB

   def initialize
      super('JOKE',
            'JOKE [<joke number>]',
            'Get a "funny" joke. If no number is provided, a random one is picked.',
            {:adminLevel => 10})
   end

   @@instance = Joke.new()

   def onCommand(responseInfo, args)
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
