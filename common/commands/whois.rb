class Whois < Command

   def initialize
      super('WHOIS',
            'WHOIS [[^]user]',
            "Get some info on a nick. This is not for info on a user of #{IRC_NICK}. For that, use USER-INFO.",
            {:aliases => ['IP']})

      # { target_nick => [ responseInfo to respond to ] }
      @pendingWhois = Hash.new{|hash, key| hash[key] = Array.new()}
   end

   @@instance = Whois.new()

   def onCommand(responseInfo, args)
      if (!match = args.strip.match(/^\^?(\S+)$/))
         responseInfo.respond("Bad syntax, try HELP WHOIS.")
         return
      end

      nick = match[1]
      user = responseInfo.server.getUser(nick)

      if (!user)
         responseInfo.respond("Sorry, I do not know about ^#{nick}.")
         return
      end

      if (user.address)
         responseInfo.respond("^#{nick} -- Address: #{user.address}, Extra Info: #{user.extraInfo}.")
         return
      else
         @pendingWhois[nick] << responseInfo
         responseInfo.server.whois(nick)
      end
   end

   def onUserInfo(nick, infoType, info)
      if (infoType != 'WHOIS')
         return
      end

      if (@pendingWhois.has_key?(nick))
         user = Bot::instance.getUser(nick)
         if (!user)
            @pendingWhois[nick].each{|responseInfo|
               responseInfo.respond("Sorry, I do not know about ^#{nick}.")
            }
         else
            @pendingWhois[nick].each{|responseInfo|
               responseInfo.respond("^#{nick} -- Address: #{user.address}, Extra Info: #{user.extraInfo}.")
            }
         end
         @pendingWhois.delete(nick)
      end
   end
end
