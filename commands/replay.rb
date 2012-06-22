class Replay < Command
   include DB
   include RateLimit

   def initialize
      super('REPLAY',
            'REPLAY LAST <minutes>',
            'Replay the last n minutes.')
   end

   @@instance = Replay.new()
   @@max_res = 100

   def onCommand(responseInfo, args)
      if (match = args.strip.match(/^LAST\s+(\d+)$/i))
         startTime = Time.now().to_i() - (match[1].to_i * 60)

         if (!responseInfo.target.start_with?('#'))
            # A PM, check user
            query = "SELECT timestamp, `from`, message" + 
                    " FROM #{LOG_TABLE}" +
                    " WHERE timestamp >= #{startTime}" +
                    "  AND `to` = '#{responseInfo.target}'" + 
                    "  AND `from` = '#{responseInfo.fromUser}'" + 
                    " ORDER BY timestamp"
         else
            query = "SELECT timestamp, `from`, message" + 
                    " FROM #{LOG_TABLE}" +
                    " WHERE timestamp >= #{startTime}" +
                    "  AND `to` = '#{responseInfo.target}'" + 
                    " ORDER BY timestamp"
         end

         res = db.query(query)

         if (res.num_rows() == 0)
               responseInfo.respondPM("No results.")
         elsif (res.num_rows() > @@max_res)
               responseInfo.respondPM("Sorry, that request generated too many results. Bug eriq about threading if you want to be able to do large requests.")
         else
            res.each{|row|
               responseInfo.respondPM("[#{Time.at(row[0].to_i)}] ^#{row[1]}: #{row[2]}")
            }
         end
      else
         responseInfo.respond("I don't understand that time, just use an int.")
      end
   end
end
