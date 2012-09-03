require './core/thread/queue_thread.rb'

# InputHandlers take input from the InputThread.
# All InputHandlers are automatically registered to recieve input upon creation.
class InputHandler < QueueThread
   include ClassUtil

   RELOADABLE_CONSTANT('SERVER_INPUT', 0)
   RELOADABLE_CONSTANT('STDIN_INPUT', 1)
   RELOADABLE_CONSTANT('PERIODIC_ACTIONS', 2)

   def self.handlers()
      return @@handlers
   end

   # |action| is one of SERVER_INPUT, STDIN_INPUT, or PERIODIC_ACTIONS.
   def self.queueTask(action, data)
      @@handlers.each{|handler|
         handler.queueTask(action, data)
      }
   end

   protected
   
   # Support reinit
   RELOADABLE_CLASS_VARIABLE('@@handlers', Array.new())

   def initialize()
      super()

      @@handlers << self
   end
end
