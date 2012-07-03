# encoding: utf-8

require 'thread'

require './users.rb'
require './constants.rb'
require './command_core.rb'

# Load all the utilities
Dir["#{UTIL_DIR}/*.rb"].each{|file|
   require file
}

# Load all the core
Dir["#{CORE_DIR}/*.rb"].each{|file|
   require file
}

# Load all the commands from COMMAND_DIR
Dir["#{COMMAND_DIR}/*.rb"].each{|file|
   require file
}

# Load all the threads!
Dir["#{THREAD_DIR}/*.rb"].each{|file|
   require file
}

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
