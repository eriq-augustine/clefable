# encoding: utf-8

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

ClefableThread.init()

server = Server.new(IRC_HOST, IRC_PORT, IRC_NICK)
server.start()

#Request the user list now
DEFAULT_CHANNELS.each{|channel|
   Clefable.instance.join(channel)
   OutputServer.queueMessage("NAMES #{channel}", 0)
}

#TODO: Get rid of stupid sleep
while (true)
   sleep(999)
end
