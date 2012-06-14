require 'net/http'
require 'json'

#'http://chromium-status.appspot.com/current?format=json'

class Tree < Command
   include TextStyle

   def initialize
      super('TREE',
            'TREE',
            'Check the tree status.')
   end

   @@instance = Tree.new()

   # Should be constant, but using class instance instead to avoid redef warning.
   @@statusUri = URI('http://chromium-status.appspot.com/current?format=json')

   def onCommand(responseInfo, args, onConsole)
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
         #puts ex.message  
         #puts ex.backtrace.inspect 
         message = 'Sorry, there was a problem fetching the tree status.'
      end
      
      responseInfo.respond(message)
   end
end