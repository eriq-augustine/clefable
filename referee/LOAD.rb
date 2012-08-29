Loader::loadDir('./referee/config')
Loader::loadDir('./referee/util')
Loader::loadDir('./referee/commands')

# The core Game class needs to be loaded before any specific game.
require './referee/game.rb'

Loader::loadDir('./referee/games')
Loader::loadAllInDir('./referee')

# Webui last.
Loader::loadDir('./referee/webui')
