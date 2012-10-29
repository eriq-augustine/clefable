class Glossary < Command
   include DB

   def initialize
      super('WHAT',
            'WHAT <word / phrase> | WHAT -A <word / phrase> ! <description>; WHAT -R <word / phrase>',
            'Lookup what a word/phrase means; Add a word/phrase into the glossary; Remove a word/phrase from the glossary.' +
            ' Adding and Removing requires at least admin level 5. Great for TLA.',
            {:aliases => @@aliases})
   end

   def insertWord(word, desc, user)
      return dbUpdate("REPLACE INTO #{GLOSSARY_TABLE} (word, description, `user`) VALUES ('#{escape(word)}', '#{escape(desc)}', '#{escape(user)}')")
   end

   def removeWord(word)
      return dbUpdate("DELETE FROM #{GLOSSARY_TABLE} WHERE word = '#{escape(word)}'")
   end

   def getDesc(word)
      res = dbQuery("SELECT description FROM #{GLOSSARY_TABLE} WHERE word = '#{escape(word)}'")
      if (!res || res.num_rows() == 0)
         return nil
      end

      row = res.fetch_row()
      return row[0]
   end

   def onCommand(responseInfo, args)
      args.strip!

      if (match = args.match(/^-A\s+(.+)\s*!\s*(.*)\s*$/i))
         user = responseInfo.fromUser
         userInfo = responseInfo.fromUserInfo

         execResponse = userInfo.canExecuteAtLevel?(@@level)
         if (!execResponse[:success])
            responseInfo.respond(execResponse[:error])
            return
         end

         if(insertWord(match[1], match[2], user))
            responseInfo.respond('Entry successfully added.')
         else
            responseInfo.respond('Sorry, there was a problem adding your entry.')
         end
      elsif (match = args.match(/^-R\s+(.+)\s*$/i))
         user = responseInfo.fromUser
         userInfo = responseInfo.fromUserInfo

         execResponse = userInfo.canExecuteAtLevel?(@@level)
         if (!execResponse[:success])
            responseInfo.respond(execResponse[:error])
            return
         end

         if (removeWord(match[1]))
            responseInfo.respond('Entry successfully removed.')
         else
            responseInfo.respond('Sorry, there was a problem removing your entry.')
         end
      elsif (args.length > 0)
         if (desc = getDesc(args))
            responseInfo.respond("#{args} -- #{desc}")
         else
            responseInfo.respond("There is no entry for '#{args}'")
         end
      else
         responseInfo.respond('I don''t understand. Try HELP WHAT.')
      end
   end

   @@level = 5
   @@aliases = ['?', 'WHAT?']
   # Disable for nlp
   #@@instance = Glossary.new()
end
