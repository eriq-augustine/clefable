require 'digest/sha2'

class EmailCommand < Command
   include DB
   include Options
   include Email

   def initialize
      super('EMAIL',
            'EMAIL; EMAIL -R <email>; EMAIL -V <verification token>',
            'View your currenly registered email; Register a new email; Verify an email.')
   end

   @@instance = EmailCommand.new()

   @@option_register_schema = OptionSchema.new('R', 'REGISTER', OptionSchema::YES_VALUE)
   @@option_verify_schema = OptionSchema.new('V', 'VERIFY', OptionSchema::YES_VALUE)
   @@optionSchema = {@@option_register_schema.shortForm.upcase => @@option_register_schema,
                     @@option_register_schema.longForm.upcase => @@option_register_schema,
                     @@option_verify_schema.shortForm.upcase => @@option_verify_schema,
                     @@option_verify_schema.longForm.upcase => @@option_verify_schema}

   def generateToken()
      str = ''
      for i in 0..10
         str += "#{Random.rand()}"
      end

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
      elsif (parsedOptions.hasOptionSchema?(@@option_register_schema))
         token = generateToken()
         email = parsedOptions.lookupValue(@@option_register_schema)
         update("REPLACE INTO #{EMAIL_TABLE} (`user`, email, token) VALUES"+
                " ('#{escape(requestUser.nick)}', '#{escape(email)}', '#{token}')")
         body = "This is your verification token:\n" +
                "#{token}\n" +
                "Use this token with EMAIL -V <token> to verify your email.\n\n"
         sendMail("Clefable Email Verification", body, email)
         responseInfo.respond("A verification email has been sent.")
      elsif (parsedOptions.hasOptionSchema?(@@option_verify_schema))
         token = parsedOptions.lookupValue(@@option_verify_schema)
         if (!(dbInfo = query("SELECT email, token FROM #{EMAIL_TABLE} WHERE `user` = '#{requestUser.nick}'")) ||
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
            update("UPDATE #{USERS_TABLE} SET email = '#{escape(email)}' WHERE `user` = '#{escape(requestUser.nick)}'")
            update("DELETE FROM #{EMAIL_TABLE} WHERE `user` = '#{escape(requestUser.nick)}'")
            responseInfo.respond("Your email has been registered!")
         end
      else
         puts "UNREACHABLE -- email"
         responseInfo.respond("What? Try HELP EMAIL")
      end
   end
end
