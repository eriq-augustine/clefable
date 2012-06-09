# TODO: use DB
class SendMessage < Command
   def initialize
      super('SEND-MESSAGE',
            'SEND-MESSAGE [!INCOGNITO] <to user> <message>',
            'Send a message to a user. If they are in the channel, it will just repeat it.' +
             'However if they are gone, the message will be sent when they return.')

      @messageQueue = Hash.new()
   end

   @@instance = SendMessage.new()

   def onCommand(responseInfo, args, onConsole = false)
      if (match = args.strip.match(/^(\S+)\s+(.+)$/))
         if (match[1].upcase == '!INCOGNITO')
            incognitoMatch = match[2].match(/^(\S+)\s+(.+)$/)
            toUser = incognitoMatch[1]
            payload = incognitoMatch[2]
            message = "Message recieved on #{Time.now()}: #{payload}"
         else
            toUser = match[1]
            payload = match[2]
            message = "Message from #{responseInfo.fromUser} recieved on #{Time.now()}: #{payload}"
         end

         if (responseInfo.server.globalHasUser?(toUser))
            responseInfo.server.chat(toUser, "#{toUser}: #{message}")
         else
            if (!@messageQueue.has_key?(toUser))
               @messageQueue[toUser] = Array.new()
            end

            @messageQueue[toUser] << message
         end
      else
         responseInfo.respond("USAGE: #{@usage}")
      end
   end

   def onUserPresence(server, channel, user)
      if (@messageQueue.has_key?(user))
         @messageQueue[user].each{|message|
            server.chat(channel, "#{user}: #{message}")
         }
         @messageQueue.delete(user)
      end
   end
end
