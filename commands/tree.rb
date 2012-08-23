require './core/logging.rb'

require 'net/http'

#'http://chromium-status.appspot.com/current?format=json'

class Tree < Command
   include TextStyle

   def initialize
      super('TREE',
            'TREE',
            'Check the tree status.',
            {:aliases => ['TREE?']})
   end

   @@instance = Tree.new()

   # Should be constant, but using class instance instead to avoid redef warning.
   @@statusUri = URI('http://chromium-status.appspot.com/current?format=json')

   def onCommand(responseInfo, args)
      message = ''

      begin
         status = JSON.parse(Net::HTTP.get(@@statusUri))
         state = "#{status['general_state'].strip.upcase}"
         if (state == 'OPEN')
            state = green(state)
         elsif (state == 'CLOSED')
            state = red(state)
         elsif (state == 'THROTTLED')
            state = yellow(state)
         end

         message = "#{bold(state)} -- #{status['message']}"
      rescue Exception => ex
         log(ERROR, ex.message)
         log(ERROR, ex.backtrace.inspect)
         message = 'Sorry, there was a problem fetching the tree status.'
      end
      
      responseInfo.respond(message)
   end
end
