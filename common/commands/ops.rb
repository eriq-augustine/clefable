class Ops < Command
   def initialize
      super('OPS',
            'OPS [GIVE [[^]<user>] | TAKE [[^]<user>]]',
            'GIVE ops to a user; TAKE ops from a user. If no user is given, the caller is assumed.' +
            ' This command will blindly be executed, but will silently fail if I don\'t have ops.',
            {:adminLevel => 1})
   end


   def onCommand(responseInfo, args)
      args.strip!

      if (!responseInfo.target.start_with?('#'))
         responseInfo.respond('You must be in a channel to manage OPS.')
         return
      end

      if (match = args.match(/^((?:GIVE)|(?:TAKE))\s*\^?(\S*)$/i))
         if (match[2].length == 0)
            user = responseInfo.fromUser
         else
            user = match[2]
         end

         if (user == IRC_NICK)
            responseInfo.respond('You cannot make me take my own OPS!')
            return
         end

         if (match[1].upcase == 'GIVE')
            responseInfo.server.giveOps(user, responseInfo.target)
         else
            responseInfo.server.takeOps(user, responseInfo.target)
         end
      else
         responseInfo.respond('I don\'t understand. Try HELP OPS.')
      end
   end
   
   @@instance = Ops.new()
end
