# encoding: utf-8

# Additional directories for the top level loader to load.
ADDITIONAL_LOAD_DIRS = ['clefable']

# Start the loading process.
require './LOAD.rb'

require 'thread'

# Choose Clefable as the active bot
Clefable.new()

BotThread.instance()

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
