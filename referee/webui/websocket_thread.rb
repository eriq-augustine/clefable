require 'em-websocket'

class WebSocketThread < ThreadWrapper
   def initialize()
      super()
   end

   protected

   def run()
      #serverInstance = WebSocketServer.new('localhost', '7070')
      serverInstance = WebSocketServer.new('0.0.0.0', '7070')
   end
end
