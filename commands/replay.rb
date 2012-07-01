class Replay < Command
   include DB
   include Options
   include Email

   def initialize
      super('REPLAY',
            'REPLAY -M <minutes> [-E [<email>]]',
            'Replay the last n minutes. If an email is supplied, Clefable will email you the results.' + 
            ' If -E is supplied without an email, Clefable will used the email you registered with EMAIL')
   end

   @@instance = Replay.new()
   @@max_res = 100

   @@option_min_schema = OptionSchema.new('M', 'MINUTES', OptionSchema::YES_VALUE)
   @@option_email_schema = OptionSchema.new('E', 'EMAIL', OptionSchema::MAYBE_VALUE)
   @@optionSchema = {@@option_min_schema.shortForm.upcase => @@option_min_schema,
                     @@option_min_schema.longForm.upcase => @@option_min_schema,
                     @@option_email_schema.shortForm.upcase => @@option_email_schema,
                     @@option_email_schema.longForm.upcase => @@option_email_schema}

   def onCommand(responseInfo, args)
      parsedOptions = parseOptions(args, @@optionSchema)

      if (parsedOptions.error)
         responseInfo.respond(parsedOptions.errorStr)
         return
      end

      if (!parsedOptions.options.key?(@@option_min_schema.to_s))
         responseInfo.respond("You need to specify a number of minutes.")
         return
      else
         min = parsedOptions.options[@@option_min_schema.to_s].to_i
         if (min == 0)
            responseInfo.respond("Use a non-zero int.")
            return
         end

         startTime = Time.now().to_i() - (min * 60)

         email = nil
         if (parsedOptions.hasOptionSchema?(@@option_email_schema))
            email = parsedOptions.lookupValue(@@option_email_schema)
            if (!email)
               user = responseInfo.server.getUsers()[responseInfo.fromUser]
               if (!user.isAuth?)
                  responseInfo.respond('If you want to use implicit email, you need to AUTH first.')
                  return
               end

               email = user.email
               if (!email)
                  responseInfo.respond('I could not find your email. Either supply one, or register one with EMAIL -R')
                  return
               end
            end
         end

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
               responseInfo.respond("No results.")
         elsif (res.num_rows() > @@max_res && !email)
               responseInfo.respond("Sorry, that request generated too many results to say in IRC." +
                                      " You can have them emailed to you with the -e/--email option.")
         else
            if (!email)
               res.each{|row|
                  responseInfo.respondPM("[#{Time.at(row[0].to_i)}] ^#{row[1]}: #{row[2]}")
               }
            else
               body = ''
               res.each{|row|
                  body += "[#{Time.at(row[0].to_i)}] ^#{row[1]}: #{row[2]}\n"
               }
               sendMail("REPLAY -m #{min}", body, email)
               responseInfo.respond("Email sent.")
            end
         end
      end
   end
end
