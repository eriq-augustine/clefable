# The top level loader.
# Handle all the loading of all files.
# For more info on load order, dependencies, and best practices, see notes/require.txt
#
# Before the top level loader is called, ADDITIONAL_LOAD_DIRS can be defined to
# list additional loads.

if (!defined?(ADDITIONAL_LOAD_DIRS))
   ADDITIONAL_LOAD_DIRS = []
end

# Every dir to load in proper order.
DIRS_TO_LOAD = ['config', 'lib', 'core', 'common'] + ADDITIONAL_LOAD_DIRS

module Loader
   # Load a directory.
   #  First look for a 'LOAD.rb'. If it exists, then let it handle the loading for the directory.
   #  Else, just load all the files in lexicographic order.
   # |dir| should be an absolute path from the project root.
   def self.loadDir(dir)
      # Use the loader if it exists
      if (File::exists?("#{dir}/LOAD.rb"))
         require "#{dir}/LOAD.rb"
      else
         # No loader, load every file in lexicographical order.
         Loader::loadAllInDir(dir)
      end
   end

   def self.loadAllInDir(dir)
      Dir["#{dir}/*.rb"].each{|file|
         require file
      }
   end
end

DIRS_TO_LOAD.each{|dir|
   Loader::loadDir("./#{dir}")
}
