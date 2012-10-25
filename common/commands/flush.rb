class Flush < Command
   def initialize
      super('FLUSH',
            'FLUSH',
            "FLUSH the #{IRC_NICK}'s pipeline. This will flush all the commands and output in the queue." +
            ' Be aware, the commands were probably already executed and only the ouput will be flushed',
            {:adminLevel => 10, :aliases => ['INT', 'KILL', 'INTERRUPT', '!']})
   end

   @@instance = Flush.new()

   def onCommand(responseInfo, args)
      BotThread.instance.killQueue
      OutputThread.instance.killQueue
      responseInfo.respond('Pipeline flushed.')
   end
end
