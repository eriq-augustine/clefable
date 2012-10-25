class NlpBot < Bot
   attr_reader :chatMode

   def initialize()
      super()

      @chatMode = false
   end

   def handleUtterance(responseInfo, utterance)
      if (!@chatMode)
         return
      end

      if (match = utterance.match(/^((?:hi)|(?:hello))/i))
         responseInfo.respond("#{responseInfo.fromUser}: #{match[1].capitalize()} there.")
      end
   end

   def enterChatMode()
      @chatMode = true
   end

   def leaveChatMode()
      @chatMode = false
   end

 private

end
