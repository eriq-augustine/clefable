require './core/logging.rb'

require 'digest/sha2'

class EmailCommand < Command
   include DB
   include Options
   include Email

   def initialize
      super('EMAIL',
            'EMAIL',
            'View your currenly registered email; Register a new email; Verify an email.',
            {:optionUsage => Options::formatOptionUsage(@@schema.values)})
   end


   @@schema = {:register =>  OptionSchema.new('Request an email to be registerd to your current nick', 'R', 'REGISTER', OptionSchema::YES_VALUE),
               :verify =>  OptionSchema.new('Use a verification token to verify a registered email', 'V', 'VERIFY', OptionSchema::YES_VALUE)}
   @@optionSchema = Hash.new()
   @@schema.each_value{|option|
      @@optionSchema[option.shortForm.upcase] = option
      @@optionSchema[option.longForm.upcase] = option
   }
   @@instance = EmailCommand.new()

   def generateToken()
      str = ''
      10.times{
         str += "#{Random.rand()}"
      }

      return Digest::SHA2.new().update(str).to_s[0, 40]
   end

   def onCommand(responseInfo, args)
      parsedOptions = parseOptions(args, @@optionSchema)

      if (parsedOptions.error)
         responseInfo.respond(parsedOptions.errorStr)
         return
      end

      users = responseInfo.server.getUsers()
      if (!users.has_key?(responseInfo.fromUser))
         responseInfo.respond('You are not loged into the system.')
         return
      end

      requestUser = users[responseInfo.fromUser]

      if (!requestUser.isAuth?)
         responseInfo.respond("You must be AUTH'd first.")
         return
      end

      # No options, echo email
      if (parsedOptions.size == 0)
         if (!requestUser.email)
            responseInfo.respond("You do not have an email currently registerd. Try EMAIL -R")
            return
         else
            responseInfo.respond("Your registered email is: #{requestUser.email}")
            return
         end
      # Too many options
      elsif (parsedOptions.size > 1)
         responseInfo.respond("Too many options, you can specify at most one option for EMAIL.")
      elsif (parsedOptions.hasOptionSchema?(@@schema[:register]))
         token = generateToken()
         email = parsedOptions.lookupValue(@@schema[:register])
         dbUpdate("REPLACE INTO #{EMAIL_TABLE} (`user`, email, token) VALUES"+
                  " ('#{escape(requestUser.nick)}', '#{escape(email)}', '#{token}')")
         body = "This is your verification token:\n" +
                "#{token}\n" +
                "Use this token with EMAIL -V <token> to verify your email.\n\n"
         sendMail("Clefable Email Verification", body, email)
         responseInfo.respond("A verification email has been sent.")
      elsif (parsedOptions.hasOptionSchema?(@@schema[:verify]))
         token = parsedOptions.lookupValue(@@schema[:verify])
         if (!(dbInfo = dbQuery("SELECT email, token FROM #{EMAIL_TABLE} WHERE `user` = '#{requestUser.nick}'")) ||
             dbInfo.num_rows() == 0)
            responseInfo.respond('Unable to find a pending email in the DB, did you EMAIL -R?')
            return
         end

         row = dbInfo.fetch_row()
         email = row[0]
         dbToken = row[1]

         if (token != dbToken)
            responseInfo.respond('Incorrect Token.')
         else
            requestUser.setEmail(email)
            dbUpdate("UPDATE #{USERS_TABLE} SET email = '#{escape(email)}' WHERE `user` = '#{escape(requestUser.nick)}'")
            dbUpdate("DELETE FROM #{EMAIL_TABLE} WHERE `user` = '#{escape(requestUser.nick)}'")
            responseInfo.respond("Your email has been registered!")
         end
      else
         log(ERROR, "UNREACHABLE -- email")
         responseInfo.respond("What? Try HELP EMAIL")
      end
   end
end
