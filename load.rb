# Handle all the loading of all files.
# constants.rb must be loaded first, to get the proper paths.

require './config/constants.rb'

require './users.rb'
require './command_core.rb'

# Continue loading all the configuration files
Dir["#{CONFIG_DIR}/*.rb"].each{|file|
   require file
}

require "#{LIB_DIR}/json/pure.rb"

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
