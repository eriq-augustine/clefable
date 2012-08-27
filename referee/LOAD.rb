Loader::loadDir('./referee/config')
Loader::loadDir('./referee/util')
Loader::loadDir('./referee/commands')
require './referee/game.rb'
Loader::loadDir('./referee/games')
Loader::loadAllInDir('./referee')
