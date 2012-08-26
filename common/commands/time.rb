require 'time'

class TimeCommand < Command
   def initialize
      super('TIME',
            'TIME',
            'Get the current time and timezone information.',
            {:aliases => ['DATE', 'DATETIME']})
   end

   @@instance = TimeCommand.new()

   def onCommand(responseInfo, args)
      responseInfo.respond("#{Time.now()}")
   end
end
