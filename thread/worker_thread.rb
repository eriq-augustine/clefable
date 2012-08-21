require './core/logging.rb'
require './thread/queue_thread.rb'

# Worker threads do async tasks (lambdas) with optional callbacks.
# Callbacks should take a single param.
# Callbacks (lambda) should NOT do any mutations.
#  But if they must, be careful.
class WorkerThread < QueueThread
   def queueTask(taskLambda, callbackLambda = lambda{|param|})
      check(taskLambda &&
            callbackLambda && 
            taskLambda.lambda? &&
            callbackLambda.lambda? &&
            taskLambda.arity == 0 &&
            callbackLambda.arity == 1)
      queue({:task => taskLambda, :callback => callbackLambda})
   end

   protected

   def processRecord(record)
      task = record[:task]
      callback = record[:callback]

      callback.call(task.call())
   end
   
   def initialize()
      super()
   end
end
