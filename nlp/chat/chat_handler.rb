require 'set'

# This is the core for handling chat.

# The chat handler is on a greater level than the TextHandlers.
# This will handle an entire conversation with a person.
# This is a static only class.
class ChatHandler
   extend ClassUtil

   RELOADABLE_CONSTANT('STALE_TIMEOUT', 60)

   RELOADABLE_CLASS_VARIABLE('@@conversations', Hash.new())
   RELOADABLE_CLASS_VARIABLE('@@handlers', Array.new())

   def initialize(user, channel)
      @user = user
      @greetingMachine = nil
      @channel = channel
      @lastSpeak = Time.now().to_i
   end

   def stale?()
      return @lastSpeak && Time.now().to_i - @lastSpeak > STALE_TIMEOUT
   end

   def update()
      @lastSpeak = Time.now().to_i
   end

   def self.addHandler(handler)
      @@handlers << handler
   end

   def self.initiate(channel)
      users = Bot.instance.channels[channel].keys()

      users.each{|user|
         if (user.match(/foaad/i) && !@@conversations.has_key?(user))
            @@conversations[user] = ChatHandler.new(user, channel)
            @@conversations[user].initiate()
            return
         end
      }

      finalUser = nil
      randUsers = users.sample(users.size())
      randUsers.each{|user|
         if (user != IRC_NICK && !@@conversations.has_key?(user))
            finalUser = user
            break
         end
      }

      if (!finalUser)
         return
      end

      @@conversations[finalUser] = ChatHandler.new(finalUser, channel)
      @@conversations[finalUser].initiate()
   end

   def self.handleChat(text, responseInfo)
      user = responseInfo.fromUser
      newChat = false

      if (!@@conversations.has_key?(user))
         @@conversations[user] = ChatHandler.new(user, responseInfo.target)
         newChat = true
      end

      handleChat = @@conversations[user].handleChatImpl(text, responseInfo)
      if (handleChat)
         @@conversations[user].update()
      elsif (!handleChat && (newChat || @@conversations[user].stale?))
         @@conversations.delete(user)
      end

      return handleChat
   end

   # If there are any current conversations, continue them.
   def self.continueConverasations()
      @@conversations.delete_if{|nick, conversation|
         !conversation.continue() || conversation.stale?
      }
   end

   def self.reset()
      @@conversations.clear()
   end

   def initiate()
      @greetingMachine = InitiateGreetingMachine.new(@user)
      Bot.instance.chat(@channel, @greetingMachine.next(''))
   end

   # A single utterance may be handled by multiple TextHandlers,
   #  but will not be handled by the same one more than once.
   # True is returned if the utterance is handled, false otherwise.
   def handleChatImpl(text, responseInfo)
      modText = text.strip()

      if (NlpBot.instance.greetingMode)
         if (!@greetingMachine && modText.match(/(hi)|(hello)/i))
            @greetingMachine = ResponseGreetingMachine.new(@user)
            responseInfo.respond(@greetingMachine.next(modText))
            return true
         end
      end

      if (@greetingMachine)
         response = @greetingMachine.next(modText)
         if (response)
            responseInfo.respond(response)
         end
         return true
      end

      fullResponse = ''
      triggeredHandlers = Set.new()

      while (true)
         talked = false

         for i in 0...@@handlers.length()
            if (!triggeredHandlers.member?(i))
               textConsumed, response = @@handlers[i].handleText(modText, responseInfo.fromUser)
               if (textConsumed)
                  triggeredHandlers.add(i)
                  talked = true
                  fullResponse += "#{response} "
                  modText = modText[textConsumed...modText.length()]
                  if (modText.length() == 0)
                     break
                  end
               end
            end
         end

         if (!talked || modText.length() == 0)
            break
         end
      end

      if (fullResponse.length() != 0)
         responseInfo.respond(fullResponse)
         return true
      end

      return false
   end

   # Continue a conversation.
   # Return true if the conversation is to be continued further.
   # Return false if the conversation is done.
   def continue()
      if (@greetingMachine)
         response = @greetingMachine.next('')
         if (response)
            Bot.instance.chat(@channel, response)
         end

         if (@greetingMachine.done?)
            @greetingMachine = nil
            return false
         end
      end

      return true
   end
end

# TextHandlers will take some input text and may consume some of that.
# Text and then generate a response.
class TextHandler
   def initialize()
      ChatHandler.addHandler(self)
   end

   # Will return nil if it will not handle some text.
   # If it can handle text, it will return two pieces of info:
   #  The number of charaters consumed.
   #  The response.
   def handleText(text, fromUser)
      notreached('Unimplemented Method')
   end

   def grabSentence(text)
      match = text.match(/^[^\.\?!]+[(\.\.\.)\.\?!]/)
      if (match)
         return match[0]
      else
         return text
      end
   end
end

class GreetingHandler < TextHandler
   def handleText(text, fromUser)
      if (match = text.match(/^\W*((?:hi)|(?:hello))/i))
         return match[0].length, "#{fromUser}: #{match[1].capitalize()} there."
      end

      return nil
   end

   @@instance = GreetingHandler.new()
end

class WellnessHandler < TextHandler
   extend ClassUtil

   RELOADABLE_CONSTANT('WELLNESS_WORDS', Set.new(['how', 'are', 'you']))

   def handleText(text, fromUser)
      sentence = grabSentence(text).downcase()
      if (Set.new(nlpSplitString(sentence)).superset?(WELLNESS_WORDS))
         #TODO: More variation
         return sentence.length(), "#{fromUser}: Pretty good, how are you?"
      else
         return nil
      end
   end

   @@insatnce = WellnessHandler.new()
end

class BirthdayHandler < TextHandler
   def handleText(text, fromUser)
      match = nil
      if ((match = text.match(/when\s+was\s+((?:(?!born)[\w\s]*))\s+born\?/i)) ||
          (match = text.match(/what\s+is\s+the\s+birthdate\s+of\s+([^\?]+)\?/i)) ||
          (match = text.match(/what\s+is\s+the\s+date\s+of\s+birth\s+of\s+([^\?]+)\?/i)) ||
          (match = text.match(/what\s+is\s+([^']+)'s\s+birthdate\?/i)) ||
          (match = text.match(/what\s+is\s+the\s+date\s+((?:(?!was)[\w\s]*))\s+was\s+born\?/i)) ||
          (match = text.match(/when\s+is\s+([^']+)'s\s+birthday\?/i)))
         doc = WikiFetcher::lookup(match[1])

         if (!doc || !doc[:bday])
            return match[0].length, "#{fromUser}: http://lmgtfy.com/?q=birthday+#{match[1].gsub(/\s+/, '+')}"
         end

         name = match[1].split().reduce(''){|rtn, val| "#{rtn} #{val.capitalize()}"}.strip()
         return match[0].length, "#{fromUser}: #{name}'s birthday is on #{doc[:bday]}."
      else
         return nil
      end
   end

   @@instance = BirthdayHandler.new()
end

class QandAHandler < TextHandler
   extend ClassUtil

   RELOADABLE_CONSTANT('QUESTION_REGEX',
      /^(?:(?:tell\s+me\s+about\s+(?:the\s+subject\s+of\s+)?)|(?:what\s+is\s+)|(?:give\s+(?:(?:(?!info).)*)info(?:rmation)?\s+about\s+)|(?:what\s+(?:(?!know).)*know\s+about))([^!\?\.]+)[!\?\.]/i)

   def handleText(text, fromUser)
      match = nil
      if (text.match(/birth/))
         return nil
      end

      if (!(match = text.strip.match(QUESTION_REGEX)))
         return nil
      end

      doc = WikiFetcher::lookup(match[1])

      if (!doc || !doc[:cleanFirstPara])
         return match[0].length, "#{fromUser}: I don't know about #{match[1]}, try: http://lmgtfy.com/?q=#{match[1].gsub(/\s+/, '+')}"
      end

      sentences = nlpSentenceSplit(doc[:cleanFirstPara])
      rtn = "#{fromUser}: "
      sentences[0...2].each{|sentence|
         rtn += "#{sentence} "
      }

      return match[0].length, rtn
   end

   @@instance = QandAHandler.new()
end
