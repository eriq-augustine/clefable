# The only actual real file that needs to be loaded it the server.
require './referee/webui/server.rb'

# Now, load the file compress all the js/css files into a single one.
require './referee/webui/resource_compiler.rb'
