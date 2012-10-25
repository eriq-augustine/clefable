# TODO(eriq): Enable for any channel.
class BotAction < Command
   def initialize
      super("BOT-ACTION",
            "BOT-ACTION <action>",
            "Have #{REAL_NAME} do an action. Equivilant of /me",
            {:aliases => ["#{IRC_NICK.sub(/_BOT$/, ''}-ACTION",
                          "#{SHORT_NICK.sub(/_BOT$/, ''}-ACTION",
                          'ACTION', 'ME']})
   end

   @@instance = BotAction.new()

   def onCommand(responseInfo, args)
      args.strip!

      if (args.length() == 0)
         responseInfo.respond("You need some action for #{SHORT_NICK} to do. See HELP #{@name}.")
         return
      end

      OutputThread.instance.queueMessage("PRIVMSG #{responseInfo.target} :#{1.chr()}ACTION #{args}#{1.chr()}", 0)
   end
end
