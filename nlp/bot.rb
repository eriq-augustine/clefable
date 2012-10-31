class NlpBot < Bot
   attr_reader :chatMode, :greetingMode, :testStoryMachine

   def initialize()
      super()

      registerPeriodicAction(lambda{ChatHandler::continueConverasations()})

      @chatMode = true
      @greetingMode = false
      @testStoryMachine = StoryMachine.new()
   end

   def handleUtterance(responseInfo, utterance)
      if (!@chatMode)
         return false
      end

      return ChatHandler.handleChat(utterance, responseInfo)
   end

   def enterGreetingMode()
      @greetingMode = true
   end

   def leaveGreetingMode()
      @greetingMode = false
   end

   def enterChatMode()
      @chatMode = true
   end

   def leaveChatMode()
      ChatHandler::reset()
      @chatMode = false
   end

   def resetConversations()
      ChatHandler::reset()
      @testStoryMachine.reset()
   end

 private

end
