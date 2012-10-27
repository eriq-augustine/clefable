## BEGIN redefining constants ##

# Remove the old constants
class Object
  __send__(:remove_const, 'IRC_NICK')
  __send__(:remove_const, 'DEFAULT_CHANNELS')
  __send__(:remove_const, 'SHORT_NICK')
  __send__(:remove_const, 'TRIGGER')
  __send__(:remove_const, 'HOST_NAME')
  __send__(:remove_const, 'SERVER_NAME')
  __send__(:remove_const, 'REAL_NAME')
end

IRC_NICK = 'P_Rainicorn-bot'
DEFAULT_CHANNELS = ['#eriq_secret', '#csc580']

SHORT_NICK = 'PRINCESS'
TRIGGER = '~'
HOST_NAME = 'CalPoly'
SERVER_NAME = 'SLO'
REAL_NAME = "Princess Rainicorn"

## END Redefining constants ##
