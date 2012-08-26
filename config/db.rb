module DB
   # Connection info
   #MYSQL_HOST = 'localhost'
   MYSQL_HOST = '50.131.15.127'
   MYSQL_USER = 'clefable'
   MYSQL_PASS = 'KantoMtMoon'
   MYSQL_DB = 'clefable_bot'

   # All the tables
   LOG_TABLE = 'logs'
   DANCE_TABLE = 'dances'
   JOKES_TABLE = 'jokes'
   FACTS_TABLE = 'facts'
   USERS_TABLE = 'users'
   NOTES_TABLE = 'notes'
   NOTE_TAGS_TABLE = 'note_tags'
   MESSAGES_TABLE = 'messages'
   REWRITE_TABLE = 'rewrite_rules'
   GLOSSARY_TABLE = 'glossary'
   COMMIT_TABLE = 'commits'
   EMAIL_TABLE = 'pending_emails'
   NICK_MAP_TABLE = 'nick_map'

   # Settings
   QUERY_AGGREGATE_MAX = 1000
end
