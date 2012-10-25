class NickMap < Command
   include DB
   include Options

   def initialize
      super('NICK-MAP',
            'NICK-MAP [OPTIONS] [^]<nick>',
            'Work with the mapping between nicks and emails.' +
            ' This map is not related to `EMAIL.' +
            ' This map is mainly used when checking for commits.',
            {:adminLevel => 5,
             :optionUsage => Options::formatOptionUsage(@@schema.values),
             :aliases => ['EMAIL-MAP']})
   end

   @@schema = {:add => OptionSchema.new('Add/Replace a mapping into/in the database', 'A', 'ADD', OptionSchema::YES_VALUE, 'EMAIL'),
               :remove => OptionSchema.new('Remove a mapping from the database', 'R', 'REMOVE', OptionSchema::NO_VALUE),
               :query => OptionSchema.new('Query the database for a mapping', 'Q', 'QUERY', OptionSchema::NO_VALUE)}
   @@optionSchema = Hash.new()
   @@schema.each_value{|option|
      @@optionSchema[option.shortForm.upcase] = option
      @@optionSchema[option.longForm.upcase] = option
   }

   @@instance = NickMap.new()

   def onCommand(responseInfo, args)
      parsedOptions = parseOptions(args, @@optionSchema)

      if (parsedOptions.error)
         responseInfo.respond(parsedOptions.errorStr)
         return
      end

      if (parsedOptions.size() != 1)
         responseInfo.respond('You must supply one and only one option to NICK-MAP.')
         return
      end

      nick = parsedOptions.args
      if (!nick || (nick = nick.strip).length == 0 || nick == '^')
         responseInfo.respond('You must specify a valid nick.')
         return
      end
      nick.sub!(/\^/, '')

      if (parsedOptions.hasOptionSchema?(@@schema[:add]))
         fullEmail = parsedOptions.lookupValue(@@schema[:add]).strip

         if (!(match = fullEmail.match(/^([^@]+)@(.+)$/)))
            responseInfo.respond("Invalid email: #{fullEmail}")
            return
         end

         email = match[1]
         domain = match[2]

         dbUpdate("REPLACE INTO #{NICK_MAP_TABLE} (nick, email, domain) VALUES ('#{escape(nick)}', '#{escape(email)}', '#{escape(domain)}')")
         Bot.instance.emailMap[nick] = {:email => email, :domain => domain}
         responseInfo.respond("Mapping added.")
      elsif (parsedOptions.hasOptionSchema?(@@schema[:remove]))
         Bot.instance.emailMap.delete(nick)
         dbUpdate("DELETE FROM #{NICK_MAP_TABLE} WHERE nick = '#{escape(nick)}'")
         responseInfo.respond("Mapping removed.")
      elsif (parsedOptions.hasOptionSchema?(@@schema[:query]))
         email = Bot.instance.emailMap[nick]
         if (email)
            responseInfo.respond("^#{nick} => #{email[:email]}@#{email[:domain]}")
            return
         else
            responseInfo.respond("There is no email mapping for ^#{nick}.")
            return
         end
      else
         responseInfo.respond('You did not supply a valid option, check `HELP NICK-MAP')
         return
      end
   end
end
