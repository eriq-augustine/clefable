# This state machine handles greetings.
class GreetingMachine
   def initialize(nick)
      @nick = nick
   end

   def done?()
      not_reached('done?')
   end

   # Return the next text. nil if there is nothing more
   def next(text)
      response = nextImpl(text)
      if (response)
         return "#{@nick}: #{response}"
      else
         return nil
      end
   end
end

class ResponseGreetingMachine < GreetingMachine
   STATE_INITIAL = 0
   STATE_INQUERY_RESPONSE_1 = 1
   STATE_INQUERY_RESPONSE_2 = 2
   STATE_INQUERY = 3
   STATE_INQUERY_WAIT_1 = 4
   STATE_INQUERY_WAIT_2 = 5
   STATE_END = 6
   STATE_GIVEUP = 7

   def initialize(nick)
      super(nick)
      @state = STATE_INITIAL
   end

   def done?()
      return @state == STATE_END
   end

   def nextImpl(text)
      case @state
      when STATE_INITIAL
         if (text.match(/(hi)|(hello)/i))
            @state = STATE_INQUERY_RESPONSE_1
            return "Hey there #{@nick}."
         else
            return nil
         end
      when STATE_INQUERY_RESPONSE_1
         if (text.match(/how.*are/i))
            @state = STATE_INQUERY
            return "Pretty good."
         else
            @state = STATE_INQUERY_RESPONSE_2
            return "Hey there #{@nick}."
         end
      when STATE_INQUERY_RESPONSE_2
         if (text.match(/how.*are/i))
            @state = STATE_INQUERY
            return "Pretty good."
         else
            @state = STATE_GIVEUP
            return nil
         end
      when STATE_INQUERY
         @state = STATE_INQUERY_WAIT_1
         return "How are you?"
      when STATE_INQUERY_WAIT_1
         if (text == '')
            @state = STATE_INQUERY_WAIT_2
            return 'How are you??'
         else
            @state = STATE_END
            return 'k cool, we are done here.'
         end
      when STATE_INQUERY_WAIT_2
         if (text == '')
            @state = STATE_GIVEUP
            return nil
         else
            @state = STATE_END
            return 'k cool, we are done here.'
         end
      when STATE_END
         return nil
      when STATE_GIVEUP
         @state = STATE_END
         return 'Whatever...'
      else
         not_reached('Bad State')
      end
   end
end

class InitiateGreetingMachine < GreetingMachine
   STATE_INITIAL = 0
   STATE_INQUERY_1 = 1
   STATE_INQUERY_2 = 2
   STATE_INQUERY_WAIT_1 = 3
   STATE_INQUERY_WAIT_2 = 4
   STATE_INQUERY_RESPONSE_1 = 5
   STATE_INQUERY_RESPONSE_2 = 6
   STATE_END = 7
   STATE_GIVEUP = 8

   def initialize(nick)
      super(nick)
      @state = STATE_INITIAL
   end

   def done?()
      return @state == STATE_END
   end

   def nextImpl(text)
      case @state
      when STATE_INITIAL
         @state = STATE_INQUERY_1
         return "Hey there #{@nick}."
      when STATE_INQUERY_1
         if (text != '')
            @state = STATE_INQUERY_WAIT_1
            return 'How are you?'
         else
            @state = STATE_INQUERY_2
            return nil
         end
      when STATE_INQUERY_2
         if (text != '')
            @state = STATE_INQUERY_WAIT_1
            return 'How are you?'
         else
            @state = STATE_GIVEUP
            return nil
         end
      when STATE_INQUERY_WAIT_1
         if (text == '')
            @state = STATE_INQUERY_WAIT_2
            return 'How are you??'
         else
            @state = STATE_INQUERY_RESPONSE_1
            return nil
         end
      when STATE_INQUERY_WAIT_2
         if (text == '')
            @state = STATE_GIVEUP
            return nil
         else
            @state = STATE_INQUERY_RESPONSE_1
            return nil
         end
      when STATE_INQUERY_RESPONSE_1
         if (text == '')
            @state = STATE_INQUERY_RESPONSE_2
            return nil
         else
            @state = STATE_END
            return "Pretty good, our greeting here is done. Move along."
         end
      when STATE_INQUERY_RESPONSE_2
         if (text == '')
            @state = STATE_GIVEUP
            return nil
         else
            @state = STATE_END
            return "Pretty good, our greeting here is done. Move along."
         end
      when STATE_END
         return nil
      when STATE_GIVEUP
         @state = STATE_END
         return 'Whatever...'
      else
         not_reached('Bad State')
      end
   end
end
