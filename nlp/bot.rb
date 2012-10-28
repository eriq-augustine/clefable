class NlpBot < Bot
   attr_reader :chatMode

   def initialize()
      super()

      registerPeriodicAction(lambda{ChatHandler::continueConverasations()})

      @chatMode = false
   end

   def handleUtterance(responseInfo, utterance)
      if (!@chatMode)
         return
      end

      ChatHandler.handleChat(utterance, responseInfo)
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
