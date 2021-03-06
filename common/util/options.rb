class OptionSchema
   NO_VALUE = 0
   YES_VALUE = 1
   MAYBE_VALUE = 2

   attr_reader :desc, :shortForm, :longForm, :valuePresence

   # valuePresence should be one of the above enum.
   def initialize(desc, shortForm, longForm, valuePresence, valueName = 'value')
      @desc = desc
      @shortForm = shortForm
      @longForm = longForm
      @valuePresence = valuePresence
      @valueName = valueName
   end

   def to_s
      rtn = ''
      if (@shortForm)
         rtn += "-#{@shortForm}"

         if (@longForm)
            rtn += "/--#{@longForm}"
         end
      elsif (@longForm)
         rtn += "--#{@longForm}"
      end

      if (valuePresence == YES_VALUE)
         rtn += " <#{@valueName}>"
      elsif (valuePresence == MAYBE_VALUE)
         rtn += " [<#{@valueName}>]"
      end

      return rtn
   end
end

class ParsedOptions
   attr_reader :options, :args, :error

   def initialize(options, args, error)
      @options = options
      @args = args
      @error = error
   end

   def hasOptionSchema?(schema)
      return @options.key?(schema.to_s)
   end

   def key?(key)
      return @options.key?(key)
   end

   def lookupValue(schema)
      return @options[schema.to_s]
   end

   def [](key)
      return @options[key]
   end

   def size
      return options.size
   end

   def errorStr
      rtn = ''
      if (@error)
         return "Error (char: #{error[:char]}): #{error[:str]}"
      end
      return rtn
   end

   def to_s
      if (error)
         return errorStr()
      else
         rtn = ''

         rtn += "ARGS: #{@args}\n"
         rtn += "OPTIONS:\n"
         @options.each_pair{|key, val|
            rtn += "   #{key}: #{val}\n"
         }

         return rtn
      end
   end
end

# Options are greedy
module Options
   # Because of whitespace preservation in the final arg, options will have to be parsed by hand.
   # Make sure short and long forms are in the schema
   def parseOptions(text, optionsSchema)
      text.strip!

      options = {}
      currentOption = nil
      currentValue = nil

      i = 0
      while (i < text.length)
         # On an option
         if (text[i] == '-')
            if (currentOption != nil)
               # Commit the most recent option, if we got here
               #  with an option on deck, then that means that no coresponding value was
               #  found for this option, it is alone.
               if (currentOption.valuePresence == OptionSchema::YES_VALUE)
                  return ParsedOptions.new(options, '', {:char => i, :str => "#{currentOption.to_s} requires a value."})
               end

               options[currentOption.to_s] = nil
               currentOption = nil
            end

            i += 1

            # if longform, consume extra '-'
            i += 1 if (text[i] == '-')

            # If the next char is a space, then the option was empty
            if (i >= text.length || text[i] == ' ')
               return ParsedOptions.new(options, '', {:char => i, :str => 'No option name was provided.'})
            end

            optionName = ''
            while (i < text.length && text[i] != ' ')
               optionName += text[i]
               i += 1
            end

            if (!optionsSchema.key?(optionName.upcase))
               return ParsedOptions.new(options, '', {:char => i, :str => "'#{optionName}' is not a recognized option."})
            else
               currentOption = optionsSchema[optionName.upcase]
            end
         elsif (text[i] == "'" || text[i] == '"')
            # if there is no current option, then this must be the real args
            # There is a strange case where the last option does not take a value,
            #  don't think that the args are an option value.
            if (!currentOption || currentOption.valuePresence == OptionSchema::NO_VALUE)
               break
            end

            bookend = text[i]
            i += 1

            currentValue = ''
            while (text[i] != bookend)
               if (i >= text.length)
                  return ParsedOptions.new(options, '', {:char => i, :str => "Unclosed quotes."})
               end

               currentValue += text[i]
               i += 1
            end

            text += 1
         elsif (text[i] == ' ')
            i += 1
         else
            # if there is no current option, then this must be the real args
            # There is a strange case where the last option does not take a value,
            #  don't think that the args are an option value.
            if (!currentOption || currentOption.valuePresence == OptionSchema::NO_VALUE)
               break
            end

            currentValue = ''
            #consume token
            while (i < text.length && text[i] != ' ')
               currentValue += text[i]
               i += 1
            end

            i += 1
         end

         if (currentOption && currentValue)
            # Have an option and a value
            # Make sure the option supports a value
            if (currentOption.valuePresence == OptionSchema::NO_VALUE)
               return ParsedOptions.new(options, '', {:char => i, :str => "#{currentOption.to_s} does not take a value."})
            end
               
            options[currentOption.to_s] = currentValue
            currentOption = nil
            currentValue = nil
         end
      end

      # If there is an option on deck, try and commit it
      if (currentOption != nil)
         if (currentOption.valuePresence == OptionSchema::YES_VALUE)
            return ParsedOptions.new(options, '', {:char => i, :str => "#{currentOption.to_s} requires a value."})
         end

         options[currentOption.to_s] = nil
         currentOption = nil
      end

      # Remove the parsed options
      args = text[i, text.length]

      return ParsedOptions.new(options, args, nil)
   end

   # Here the schemas should be an arry of schemas.
   def self.formatOptionUsage(schemas)
      rtn = ''
      if (!schemas || schemas.size == 0)
         rtn = 'There are no options.'
      else
         schemas.each{|schema|
            rtn += "#{schema.to_s} -- #{schema.desc}; " 
         }
         rtn.sub!(/; $/, '')
      end

      return rtn
   end
end
