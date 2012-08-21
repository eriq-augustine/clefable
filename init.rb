# encoding: utf-8

# Start the loading process.
require './load.rb'

require 'thread'

ClefableThread.init()

server = Server.new(IRC_HOST, IRC_PORT, IRC_NICK)
server.start()

#Request the user list now
DEFAULT_CHANNELS.each{|channel|
   Clefable.instance.join(channel)
   OutputThread.instance.queueMessage("NAMES #{channel}", 0)
}

# Halt the main thread.
begin
   Thread.stop
rescue Interrupt
   log(INFO, 'Main thread was interrupted... shutting down server.')
rescue
   log(INFO, 'Main thread was resumed, which means death.')
end
