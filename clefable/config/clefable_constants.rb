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

#IRC_NICK = 'TEST_BOT'
#DEFAULT_CHANNELS = ['#eriq_secret', '#bestfriendsclub']

IRC_NICK = 'Clefable_BOT'
DEFAULT_CHANNELS = ['#crx', '#eriq_secret', '#bestfriendsclub', '#softwareinventions', '#clefable']

SHORT_NICK = 'CLEF'
TRIGGER = '`'
HOST_NAME = 'Mt.Moon'
SERVER_NAME = 'Kanto'
REAL_NAME = 'Clefable Bot'

## END Redefining constants ##
