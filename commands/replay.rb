class Replay < Command
   include DB
   include Options
   include Email

   def initialize
      super('REPLAY',
            'REPLAY [OPTIONS]',
            'Replay the last n minutes.',
            {:optionUsage => Options::formatOptionUsage(@@schema.values)})
   end

   @@max_res = 10

   @@schema = {:min => OptionSchema.new('Number of minutes to go back', 'M', 'MINUTES', OptionSchema::YES_VALUE),
               :email => OptionSchema.new('The email to use (if no email is supplied, your registered email is used)', 'E', 'EMAIL', OptionSchema::MAYBE_VALUE),
               :limit => OptionSchema.new('The maximum number of entries returned', 'L', 'LIMIT', OptionSchema::YES_VALUE)}
   @@optionSchema = Hash.new()
   @@schema.each_value{|option|
      @@optionSchema[option.shortForm.upcase] = option
      @@optionSchema[option.longForm.upcase] = option
   }
   @@instance = Replay.new()

   def onCommand(responseInfo, args)
      parsedOptions = parseOptions(args, @@optionSchema)

      if (parsedOptions.error)
         responseInfo.respond(parsedOptions.errorStr)
         return
      end

      if (!parsedOptions.hasOptionSchema?(@@schema[:min]))
         responseInfo.respond("You need to specify a number of minutes.")
         return
      else
         min = parsedOptions.lookupValue(@@schema[:min]).to_i
         if (min == 0)
            responseInfo.respond("Use a non-zero int for minutes.")
            return
         end

         limit = nil
         if (parsedOptions.hasOptionSchema?(@@schema[:limit]))
            limit = parsedOptions.lookupValue(@@schema[:limit]).to_i
            if (limit == 0)
               responseInfo.respond('Must specify a non-zero int for limit.')
               return
            end
         end

         startTime = Time.now().to_i() - (min * 60)

         email = nil
         if (parsedOptions.hasOptionSchema?(@@schema[:email]))
            email = parsedOptions.lookupValue(@@schema[:email])
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

         if (limit)
            query += " LIMIT #{limit}"
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
               subject = "REPLAY -M #{min} "

               if (limit)
                  subject += "-L #{limit}"
               end

               sendMail(subject, body, email)
               responseInfo.respond("Email sent.")
            end
         end
      end
   end
end
