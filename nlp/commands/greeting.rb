class EnterGreetingMode < Command
   def initialize
      super('ENTER-GREETING-MODE',
            'ENTER-GREETING-MODE',
            "Initiate greeting mode.",
            {:aliases => ['GREETING-MODE']})
   end

   @@instance = EnterGreetingMode.new()

   def onCommand(responseInfo, args)
      if (NlpBot.instance.greetingMode)
         responseInfo.respond("#{responseInfo.fromUser}: I am already in greeting mode.")
         return
      end

      NlpBot.instance.enterGreetingMode()
      responseInfo.respond("#{responseInfo.fromUser}: I am ready to greet.")
   end
end

class LeaveGreetingMode < Command
   def initialize
      super('LEAVE-GREETING-MODE',
            'LEAVE-GREETING-MODE',
            "Leave greeting mode.")
   end

   @@instance = LeaveGreetingMode.new()

   def onCommand(responseInfo, args)
      if (!NlpBot.instance.greetingMode)
         responseInfo.respond("#{responseInfo.fromUser}: I am not in greeting mode.")
         return
      end

      NlpBot.instance.leaveGreetingMode()
      responseInfo.respond("#{responseInfo.fromUser}: I no longer in greeting mode.")
   end
end


class InitiateGreet < Command
   def initialize
      super('INITIATE-GREET',
            'INITIATE-GREET',
            "Force #{IRC_NICK} to initiate a greeting.",
            {:aliases => ['GREET', 'INITIATE']})
   end

   @@instance = InitiateGreet.new()

   def onCommand(responseInfo, args)
      ChatHandler::initiate(responseInfo.target)
   end
end
