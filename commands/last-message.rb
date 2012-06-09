class LastMessage < Command
   include DB

   def initialize
      super('LAST-MESSAGE',
            'LAST-MESSAGE <user>',
            'Get the last message from given user.')
   end

   @@instance = LastMessage.new()

   def onCommand(responseInfo, args, onConsole)
      user = args.strip

      if (user.length() == 0)
         responseInfo.respond('You have to specify a user.')
      else
         res = db.query("SELECT timestamp, `to`, message" +
                        " FROM #{LOG_TABLE}" +
                        " WHERE `from` = '#{user}'" +
                        "  AND `to` LIKE '#%'" +
                        " ORDER BY timestamp DESC" +
                        " LIMIT 1")

         if (!res || res.num_rows() == 0)
            responseInfo.respond("No results for #{user}")
         else
            row = res.fetch_row()
            responseInfo.respond("Last message recied from #{user} at" + 
                                 " #{Time.at(row[0].to_i)} in #{row[1]}: #{row[2]}")
         end
      end
   end
end
