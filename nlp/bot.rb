class NlpBot < Bot
   attr_reader :chatMode

   def initialize()
      super()

      registerPeriodicAction(lambda{ChatHandler::continueConverasations()})

      @chatMode = true
   end

   def handleUtterance(responseInfo, utterance)
      if (!@chatMode)
         return false
      end

      return ChatHandler.handleChat(utterance, responseInfo)
   end

   def enterChatMode()
      @chatMode = true
   end

   def leaveChatMode()
      ChatHandler::reset()
      @chatMode = false
   end

 private

end
