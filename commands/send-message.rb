# TODO: use DB
class SendMessage < Command
   include DB

   def loadMessages()
      res = db.query("SELECT to_user, message FROM #{MESSAGES_TABLE}")
      if (res)
         res.each{|row|
            if (!@messageQueue.key?(row[0]))
               @messageQueue[row[0]] = Array.new()
            end

            @messageQueue[row[0]] << row[1]
         }
      end
   end

   def initialize
      super('SEND-MESSAGE',
            'SEND-MESSAGE [!INCOGNITO] [^]<to user> <message>',
            'Send a message to a user. If they are in the channel, it will just repeat it.' +
             'However if they are gone, the message will be sent when they return.')

      @messageQueue = Hash.new()
      loadMessages()
   end

   @@instance = SendMessage.new()

   def addMessage(toUser, message)
      if (!@messageQueue.has_key?(toUser))
         @messageQueue[toUser] = Array.new()
      end

      @messageQueue[toUser] << message

      db.query("INSERT INTO #{MESSAGES_TABLE} (to_user, message) VALUES ('#{toUser}', '#{escape(message)}')")
   end

   def removeAllMessages(toUser)
      @messageQueue.delete(toUser)
      db.query("DELETE FROM #{MESSAGES_TABLE} WHERE to_user = '#{toUser}'")
   end

   def onCommand(responseInfo, args, onConsole = false)
      if (match = args.strip.match(/^(\S+)\s+(.+)$/))
         if (match[1].upcase == '!INCOGNITO')
            incognitoMatch = match[2].match(/^(\S+)\s+(.+)$/)
            toUser = incognitoMatch[1].sub(/^\^/, '')
            payload = incognitoMatch[2]
            message = "Message recieved on #{Time.now()}: #{payload}"
         else
            toUser = match[1].sub(/^\^/, '')
            payload = match[2]
            message = "Message from #{responseInfo.fromUser} recieved on #{Time.now()}: #{payload}"
         end

         if (responseInfo.server.globalHasUser?(toUser))
            responseInfo.server.chat(toUser, "#{toUser}: #{message}")
            responseInfo.respond('Message delivered.')
         else
            addMessage(toUser, message)
            responseInfo.respond('User is not available, but message was queued.')
         end
      else
         responseInfo.respond("USAGE: #{@usage}")
      end
   end

   def onUserPresence(server, channel, user)
      if (@messageQueue.has_key?(user))
         @messageQueue[user].each{|message|
            server.chat(user, "#{user}: #{message}")
         }
      end
      removeAllMessages(user)
   end
end
