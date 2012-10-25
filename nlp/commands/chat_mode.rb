class EnterChat < Command
   def initialize
      super('ENTER-CHAT-MODE',
            'ENTER-CHAT-MODE',
            "Tell #{IRC_NICK} to enter chat mode.",
            {:aliases => ['ENTER-CHAT']})
   end

   @@instance = EnterChat.new()

   def onCommand(responseInfo, args)
      if (NlpBot.instance.chatMode)
         responseInfo.respond("#{responseInfo.fromUser}: I am already in chat mode.")
      else
         NlpBot.instance.enterChatMode()
         responseInfo.respond("I am now ready to chat!")
      end
   end
end

class LeaveChat < Command
   def initialize
      super('LEAVE-CHAT-MODE',
            'LEAVE-CHAT-MODE',
            "Tell #{IRC_NICK} to leave chat mode.",
            {:aliases => ['LEAVE-CHAT', 'DIE']})
   end

   @@instance = LeaveChat.new()

   def onCommand(responseInfo, args)
      if (NlpBot.instance.chatMode)
         NlpBot.instance.leaveChatMode()
         responseInfo.respond("I now out of chat mode, and will only respond to standard commands.")
      else
         responseInfo.respond("#{responseInfo.fromUser}: I am not in in chat mode.")
      end
   end
end
