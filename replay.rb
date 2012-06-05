require 'mysql'

MYSQL_HOST = 'localhost'
MYSQL_USER = 'clefable'
MYSQL_PASS = 'KantoMtMoon'
MYSQL_DB = 'clefable_bot'
LOG_TABLE = 'logs'

class Replay < Command
   def initialize
      super('REPLAY',
            'REPLAY LAST <minutes>',
            'Replay the last n minutes.')
      @db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
   end

   @@instance = Replay.new()

   def onCommand(server, channel, fromUser, args, onConsole)
      if (match = args.strip.match(/^LAST\s+(\d+)$/))
         startTime = Time.now().to_i() - (match[1].to_i * 60)


         puts "SELECT timestamp, `from`, message" + 
                         " FROM #{LOG_TABLE}" +
                         " WHERE timestamp >= #{startTime}" +
                         "  AND `to` = '#{channel}'" + 
                         " ORDER BY timestamp"

         res = @db.query("SELECT timestamp, `from`, message" + 
                         " FROM #{LOG_TABLE}" +
                         " WHERE timestamp >= #{startTime}" +
                         "  AND `to` = '#{channel}'" + 
                         " ORDER BY timestamp")
         res.each{|row|
            server.chat(channel, "[#{Time.at(row[0].to_i)}] #{row[1]}: #{row[2]}")
         }
      else
         server.chat(channel, "I don't understand that time, just use an int.")
      end
   end
end
