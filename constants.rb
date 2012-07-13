IRC_HOST = 'irc.freenode.net'
IRC_PORT = 6667
IRC_NICK = 'Clefable_BOT'

#Wait for 2 mins on select
SELECT_TIMEOUT = 120

#DEFAULT_CHANNELS = ['#eriq_secret', '#bestfriendsclub']
#DEFAULT_CHANNELS = ['#eriq_secret', '#clefable']
DEFAULT_CHANNELS = ['#crx', '#eriq_secret', '#bestfriendsclub', '#softwareinventions', '#clefable']
#DEFAULT_CHANNELS = ['#eriq_secret', '#bestfriendsclub', '#softwareinventions']

MAX_MESSAGE_LEN = 400

CONSOLE = '_CONSOLE_'
CONSOLE_USER = User.new(CONSOLE, false)
# TODO: Maybe don't give console user free reign
CONSOLE_USER.auth
CONSOLE_USER.setAdmin(0)

COMMAND_DIR = './commands'
UTIL_DIR = './util'
CORE_DIR = './core'
THREAD_DIR = './thread'

USER_NAME = IRC_NICK
SHORT_NICK = 'CLEF'
TRIGGER = '`'
HOST_NAME = 'Mt.Moon'
SERVER_NAME = 'Kanto'
REAL_NAME = 'Clefable Bot'

ALL_CHANNLES = 'ALL_CHANELS'
