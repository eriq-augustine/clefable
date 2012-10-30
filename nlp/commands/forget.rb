class Forget < Command
   def initialize
      super('FORGET',
            'FORGET',
            "Forget about previous conversations.",
            {:aliases => ['*FORGET']})
   end

   @@instance = Forget.new()

   def onCommand(responseInfo, args)
      NlpBot.instance.resetConversations()
      responseInfo.respond("What was I saying...")
   end
end
