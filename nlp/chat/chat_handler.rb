require 'set'

# This is the core for handling chat.

# The chat handler is on a greater level than the TextHandlers.
# This will handle an entire conversation with a person.
# This is a static only class.
class ChatHandler
   extend ClassUtil

   RELOADABLE_CLASS_VARIABLE('@@conversations', Hash.new())
   RELOADABLE_CLASS_VARIABLE('@@handlers', Array.new())

   def self.addHandler(handler)
      @@handlers << handler
   end

   # A single utterance may be handled by multiple TextHandlers,
   #  but will not be handled by the same one more than once.
   # True is returned if the utterance is handled, false otherwise.
   def self.handleChat(text, responseInfo)
      modText = text.strip()

      fullResponse = ''

      triggeredHandlers = Set.new()

      while (true)
         talked = false

         for i in 0...@@handlers.length()
            if (!triggeredHandlers.member?(i))
               textConsumed, response = @@handlers[i].handleText(modText, responseInfo.fromUser)
               if (textConsumed)
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

   # If there are any current conversations, continue them.
   def self.continueConverasations()
   end

   def self.reset()
      @@conversations.clear()
      #TODO(eriq): Make sure to reset the StoryMachines
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
      if (WELLNESS_WORDS.subset?(Set.new(nlpSplitString(sentence))))
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
      /^(?:(?:tell\s+me\s+about\s+(?:the\s+subject\s+of\s+)?)|(?:what\s+is\s+(?!the)\s+)|(?:give\s+(?:(?:(?!info).)*)info(?:rmation)?\s+about\s+)|(?:what\s+(?:(?!know).)*know\s+about))([^!\?\.]+)[!\?\.]/i)

   def handleText(text, fromUser)
      match = nil
      if (!(match = text.strip.match(QUESTION_REGEX)))
         return nil
      end

      doc = WikiFetcher::lookup(match[1])

      if (!doc || !doc[:cleanFirstPara])
         return match[0].length, "#{fromUser}: http://lmgtfy.com/?q=#{match[1].gsub(/\s+/, '+')}"
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
