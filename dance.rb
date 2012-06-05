# encoding: utf-8

require 'mysql'

MYSQL_HOST = 'localhost'
MYSQL_USER = 'clefable'
MYSQL_PASS = 'KantoMtMoon'
MYSQL_DB = 'clefable_bot'
DANCE_TABLE = 'dances'

$dances = Hash.new()

def loadDBDances
   $dances.clear();

   db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
   res = db.query("SELECT name, step FROM #{DANCE_TABLE} ORDER BY name, ordinal")

   res.each{|row|
      if (!$dances.has_key?(row[0]))
         $dances[row[0]] = Array.new()
      end

      $dances[row[0]] << row[1]
   }
end

def insertDance(server, channel, name, steps)
   insert = "INSERT INTO #{DANCE_TABLE} (name, ordinal, step) VALUES "
   steps.each_index{|index|
      insert += "('#{name}', #{index}, '#{Mysql::escape_string(steps[index])}'), "

      if (steps[index].match(/(INSERT)|(DELETE)|(SELECT)|(REPLACE)|(DROP)|(UPDATE)|(ALTER)/i))
         server.chat(channel, "HEY! You trying to give me an injection?!?")
         return;
      end
   }
   insert.sub!(/, $/, '')

   db = Mysql::new(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB)
   db.query("DELETE FROM #{DANCE_TABLE} WHERE name = '#{name}'")
   db.query(insert)
end

class Dance < Command
   def initialize
      super('DANCE',
            'DANCE [LIST | LEARN <dance name> <delim> <dance> | <dance name>]',
            'List available dances, learn a new dance, or do a little dance.')
      loadDBDances()
   end

   @@instance = Dance.new()

   def onCommand(server, channel, fromUser, args, onConsole)
      args.strip!

      if (args.length() == 0 || args.match(/^LIST$/i))
         message = 'Available dances: '
         $dances.each_key{|danceName|
            message += "#{danceName}, "
         }
         message.sub!(/, $/, '')

         server.chat(channel, message)
      # LEARN <dance name> <delim> <dance>
      elsif (args.match(/^LEARN/i))
         # TODO: Learn by going into a seperate channel
         
         if (match = args.match(/^LEARN\s+(\S+)\s+(\S+)\s+(.*)$/i))
            name = match[1]
            delim = match[2]

            # TODO: Let someone override/delete dance
            if ($dances.has_key?(name))
               server.chat(channel, 'That dance already exists, and you are not allowed to override it.');
            else
               steps = match[3].rstrip().split(delim)
               $dances[name] = steps
               insertDance(server, channel, name, steps)
            end
         else
            server.chat(channel, 'USAGE: DANCE LEARN <dance name> <delim> <dance>')
         end
      else
         if ($dances.has_key?(args))
            $dances[args].each{|line|
               server.chat(channel, line)
               sleep(0.5)
            }
         else
            server.chat(channel, "I don't know that dance.")
         end
      end
   end
end
