class Dance < Command
   include DB
   
   def initialize
      super('DANCE',
            'DANCE [LIST | REMOVE <dance name> | LEARN <dance name> <delim> <dance> | <dance name>]',
            'LIST available dances, REMOVE a dance, LEARN a new dance, or do a little dance. Delims must be a single char.')
      loadDBDances()
   end

   def onCommand(responseInfo, args)
      args.strip!

      if (args.length() == 0 || args.match(/^LIST$/i))
         message = 'Available dances: '
         @@dances.each_key{|danceName|
            message += "#{danceName}, "
         }
         message.sub!(/, $/, '')

         responseInfo.respond(message)
      # LEARN <dance name> <delim> <dance>
      elsif (args.match(/^LEARN/i))
         if (match = args.match(/^LEARN\s+(\S+)\s+(\S)(.+)$/i))
            name = match[1]
            delim = match[2]

            # TODO: Let someone override/delete dance
            if (@@dances.has_key?(name))
               responseInfo.respond('That dance already exists, and you are not allowed to override it.');
            else
               steps = match[3].rstrip().split(delim)
               insertDance(responseInfo, name, steps)
               responseInfo.respond("I have successfully learned the '#{name}' dance.")
               @@dances[name] = steps
            end
         else
            responseInfo.respond('USAGE: DANCE LEARN <dance name> <delim> <dance>')
         end
      elsif (match = args.match(/^REMOVE\s+(\S+)\s*/i))
         name = match[1]
         if (!@@dances.has_key?(name))
            responseInfo.respond("There is no dance named #{name}.")
            return
         else
            @@dances.delete(name)
            if (!dbUpdate("DELETE FROM #{DANCE_TABLE} WHERE name = '#{escape(name)}'"))
               responseInfo.respond("There was a problem removing the '#{name}' dance from the DB,"+
                                    " it was still removed from memory.")
            else
               responseInfo.respond("The '#{name}' dance was successfully removed.")
            end
         end
      else
         if (@@dances.has_key?(args))
            @@dances[args].each{|line|
               responseInfo.respond(line, {:delay => 0.5})
            }
         else
            responseInfo.respond("I don't know that dance.")
         end
      end
   end

   def loadDBDances
      @@dances.clear();

      res = dbQuery("SELECT name, step FROM #{DANCE_TABLE} ORDER BY name, ordinal")

      res.each{|row|
         if (!@@dances.has_key?(row[0]))
            @@dances[row[0]] = Array.new()
         end

         @@dances[row[0]] << row[1]
      }
   end

   def insertDance(responseInfo, name, steps)
      insert = "INSERT INTO #{DANCE_TABLE} (name, ordinal, step) VALUES "
      steps.each_index{|index|
         insert += "('#{escape(name)}', #{index}, '#{escape(steps[index])}'), "

         if (steps[index].match(/(INSERT)|(DELETE)|(SELECT)|(REPLACE)|(DROP)|(UPDATE)|(ALTER)/i))
            responseInfo.respond("HEY! You trying to give me an injection?!?")
            return;
         end
      }
      insert.sub!(/, $/, '')

      dbQuery("DELETE FROM #{DANCE_TABLE} WHERE name = '#{escape(name)}'")
      dbQuery(insert)
   end
   
   @@dances = Hash.new()
   
   @@instance = Dance.new()
end
