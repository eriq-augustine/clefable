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

   #TEST
   @@sm = StoryMachine.new()

   # A single utterance may be handled by multiple TextHandlers,
   #  but will not be handled by the same one more than once.
   def self.handleChat(text, responseInfo)
      #TEST
      responseInfo.respond(@@sm.getNext())
      return

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
      end
   end

   def self.reset()
      @@conversations.clear()
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
         return sentence.length(), "Pretty good, how are you?"
      else
         return nil
      end
   end

   @@insatnce = WellnessHandler.new()
end
