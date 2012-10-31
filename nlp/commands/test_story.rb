class TestStoryMachine < Command
   def initialize
      super('TEST-STORY-MACHINE',
            'TEST-STORY-MACHINE',
            "Test the story machine. There is only one test story machine, but FORGET will reset it.",
            {:aliases => ['STORY', 'TEST-STORY', 'STORY-MACHINE']})
   end

   @@instance = TestStoryMachine.new()

   def onCommand(responseInfo, args)
      responseInfo.respond("#{responseInfo.fromUser}: #{NlpBot.instance.testStoryMachine.getNext()}")
   end
end
