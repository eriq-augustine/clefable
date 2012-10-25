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

      puts "CHAT TIME: #{utterance}"
   end

   def enterChatMode()
      @chatMode = true
   end

   def leaveChatMode()
      @chatMode = false
   end

 private

end
