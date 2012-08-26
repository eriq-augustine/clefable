# The top level loader.
# Handle all the loading of all files.
# For more info on load order, dependencies, and best practices, see notes/require.txt

# Every dir to load in proper order.
DIRS_TO_LOAD = ['config', 'lib', 'core', 'common', 'clefable']

DIRS_TO_LOAD.each{|dir|
  # Use the loader if it exists
  if (File::exists?("./#{dir}/LOAD.rb"))
    require "./#{dir}/LOAD.rb"
  else
    # No loader, load every file in lexicographical order.
    Dir["./#{dir}/*.rb"].each{|file|
      require file
    }
  end
}
