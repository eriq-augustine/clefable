CONSOLE_USER = User.new(CONSOLE, false)
# TODO: Maybe don't give console user free reign
CONSOLE_USER.auth
CONSOLE_USER.setAdmin(0)
