require './thread/queue_thread.rb'
require './core/logging.rb'

# Handle all commands.
class ClefableThread < QueueThread
   SERVER_INPUT = 0
   STDIN_INPUT = 1
   PERIODIC_ACTIONS = 2

   @@instance = nil

   def self.init()
      @@instance = ClefableThread.new()
   end

   def self.instance
      if (!@@instance)
         LOG(FATAL, 'ClefableThread was not init() before use.')
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

      case action
      when SERVER_INPUT
         Clefable.instance.handleServerInput(data)
      when STDIN_INPUT
         Clefable.instance.handleStdinInput(data)
      when PERIODIC_ACTIONS
         Clefable.instance.periodicActions()
      else
         log(ERROR, "Unknown Clefable action: #{action}.")
      end
   end
   
   private
   
   def initialize()
      super()
   end
end
