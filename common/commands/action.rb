# TODO(eriq): Enable for any channel.
class ClefableAction < Command
   def initialize
      super('CLEFABLE-ACTION',
            'CLEFABLE-ACTION <action>',
            "Have #{REAL_NAME} do an action. Equivilant of /me",
            {:aliases => ['CLEF-ACTION', 'ACTION', 'ME']})
   end

   @@instance = ClefableAction.new()

   def onCommand(responseInfo, args)
      args.strip!

      if (args.length() == 0)
         responseInfo.respond("You need some action for clef to do. See HELP #{@name}.")
         return
      end

      OutputThread.instance.queueMessage("PRIVMSG #{responseInfo.target} :#{1.chr()}ACTION #{args}#{1.chr()}", 0)
   end
end
