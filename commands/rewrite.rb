class Rewrite < Command
   include DB
   def initialize
      super('REWRITE',
            'REWRITE [LIST | ADD <target> ! <rewrite> | REMOVE <target>]',
            'LIST all the rewrite rules; ADD a new rewrite rule; REMOVE a rewrite rule.' +
             ' Leading and trailing whitespace are generally ignored, but are allowed between words.' +
             ' Be careful, rewrite rules are not themselves rewritten.',
            {:adminLevel => 1, :skipLog => true})
   end

   @@instance = Rewrite.new()

   def insertRule(target, rewrite)
      begin
         db.query("INSERT INTO #{REWRITE_TABLE} (target, rewrite)" + 
                  " VALUES ('#{escape(target)}', '#{escape(rewrite)}')")
         return true
      rescue Exception => ex
         puts ex.message
         return false
      end
      return false
   end

   def removeRule(target)
      begin
         db.query("DELETE FROM #{REWRITE_TABLE} WHERE target = '#{escape(target)}'")
         return true
      rescue Exception => ex
         puts ex.message
         return false
      end
      return false
   end

   def onCommand(responseInfo, args, onConsole)
      args.strip!

      if (match = args.match(/^LIST/i))
         rules = ''
         responseInfo.server.rewriteRules.each_pair{|target, rewrite|
            rules += "{'#{target}' => '#{rewrite}'}, "
         }
         rules.sub!(/, $/, '')

         if (rules == '')
            responseInfo.respond('There are currently no rewrite rules.')
         else
            # Don't rewrite
            responseInfo.respond(rules, false)
         end
      elsif (match = args.match(/^ADD\s+([^!]+)\s*!\s*(.*)$/i))
         target = match[1].strip
         rewrite = match[2].strip
         if (insertRule(target, rewrite))
            responseInfo.server.rewriteRules[target] = rewrite
            responseInfo.respond('Rewrite rule successfully added.')
         else
            responseInfo.respond('There was an error adding your rewrite rule.')
         end
      elsif (match = args.match(/^REMOVE\s+(.*)$/i))
         target = match[1].strip
         if (removeRule(target))
            responseInfo.server.rewriteRules.delete(target)
            responseInfo.respond('Rewrite rule successfully removed.')
         else
            responseInfo.respond('There was an error removing your rewrite rule.')
         end
      else
         responseInfo.respond('What? Try HELP REWRITE.')
      end
   end
end
