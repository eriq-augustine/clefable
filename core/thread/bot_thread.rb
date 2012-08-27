require './core/thread/input_handler.rb'

# Handle all commands.
class BotThread < InputHandler
   @@instance = nil

   def self.init()
      @@instance = BotThread.new()
   end

   def self.instance
      if (!@@instance)
         LOG(FATAL, 'BotThread was not init() before use.')
      end

      return @@instance
   end

   def queueTask(action, data)
      queue({:action => action, :data => data})
   end

   protected

   def processRecord(record)
      action = record[:action]
      data = record[:data]

      # If there is a bot around, let it handle the input.
      if (Bot.instance)
         case action
         when SERVER_INPUT
            Bot.instance.handleServerInput(data)
         when STDIN_INPUT
            Bot.instance.handleStdinInput(data)
         when PERIODIC_ACTIONS
            Bot.instance.periodicActions()
         else
            log(ERROR, "Unknown InputHandler action: #{action}.")
         end
      else
         log(WARN, "There is no bot to accept the input.")
      end
   end
   
   private
   
   def initialize()
      super()
   end
end
