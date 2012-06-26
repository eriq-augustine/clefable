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

IRCServer.init(IRC_HOST, IRC_PORT, IRC_NICK)
IRCServer.instance.connect()

#Request the user list now
DEFAULT_CHANNELS.each{|channel|
   IRCServer.instance.join(channel)
   IRCServer.instance.sendMessage("NAMES #{channel}")
}

begin
   IRCServer.instance.listen()
rescue Interrupt
   puts '[INFO] Recieved interrupt, server shutting down...'
rescue Exception => detail
   puts detail.message()
   print detail.backtrace.join("\n")
   retry
end
