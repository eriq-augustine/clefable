class LastMessage < Command
   include DB
   include TimeConversions

   def initialize
      super('LAST-MESSAGE',
            'LAST-MESSAGE -PM [^]<user>',
            'Get the last message from given user.')
   end

   def onCommand(responseInfo, args)
      args = args.strip.upcase
      pm = false

      if (args.start_with?('-PM'))
         pm = true
         args.sub!(/^-PM\s*/, '')
      end

      user = args.sub(/^\^\s*/, '')

      if (user.length() == 0)
         message = 'You have to specify a user.'
      else
         res = db.query("SELECT timestamp, `to`, message" +
                        " FROM #{LOG_TABLE}" +
                        " WHERE `from` = '#{user}'" +
                        "  AND `to` LIKE '#%'" +
                        " ORDER BY timestamp DESC" +
                        " LIMIT 1")

         if (!res || res.num_rows() == 0)
            message = "No results for ^#{user.downcase}"
         else
            row = res.fetch_row()
            timeDiff = Time.now().to_i - row[0].to_i
            timeOptions = {:days => true, :hours => true, :mins => true}
            timeString = secsToExplodedString(timeDiff, timeOptions)
            message = "Last message recieved from ^#{user.downcase} (" + 
                      "#{timeString} ago in #{row[1]}): #{row[2]}"
            #message = "Last message recieved from ^#{user.downcase} at" + 
            #          " #{Time.at(row[0].to_i)} in #{row[1]}: #{row[2]}"
         end
      end

      if (pm)
         responseInfo.respondPM(message)
      else
         responseInfo.respond(message)
      end
   end

   @@instance = LastMessage.new()
end
