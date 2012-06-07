class Replay < Command
   include DB

   def initialize
      super('REPLAY',
            'REPLAY LAST <minutes>',
            'Replay the last n minutes.')
   end

   @@instance = Replay.new()

   # TODO: This allows others to see PM to Clefable, fix that by checking from if PM.
   def onCommand(responseInfo, args, onConsole)
      if (match = args.strip.match(/^LAST\s+(\d+)$/))
         startTime = Time.now().to_i() - (match[1].to_i * 60)

         res = db.query("SELECT timestamp, `from`, message" + 
                         " FROM #{LOG_TABLE}" +
                         " WHERE timestamp >= #{startTime}" +
                         "  AND `to` = '#{responseInfo.target}'" + 
                         " ORDER BY timestamp")
         if (res.num_rows() == 0)
               responseInfo.respondPM("No results.")
         else
            res.each{|row|
               responseInfo.respondPM("[#{Time.at(row[0].to_i)}] #{row[1]}: #{row[2]}")
               sleep(0.2)
            }
         end
      else
         responseInfo.respond("I don't understand that time, just use an int.")
      end
   end
end
