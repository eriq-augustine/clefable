module Nlp
   # Split a string
   def self.splitString(text)
      return text.split()
   end

   def self.unigrams(text, removeStopwords = false)
      modText = text.gsub(/['-]/, '')
      modText.gsub!(/\W/, ' ')
      modText.gsub!(/\s+/, ' ')

      unigrams = modText.downcase().split()

      if (!removeStopwords)
         return unigrams
      end

      rtn = []
      unigrams.each{|gram|
         if (!stopword?(gram))
            rtn << gram
         end
      }

      return rtn
   end

   # Naive Split
   # Fuck it, 3 part replace.
   def self.sentenceSplit(text)
      rtn = []

      periodReplace = '@@'
      periodRegex = /((?:P)|(?:S)|(?:Mr)|(?:Mrs)|(?:Ms)|(?:Mme)|(?:Sta)|(?:Sr)|(?:Sra)|(?:Dr))\./

      text.gsub(/[\s\n]+/, ' ').strip().gsub(periodRegex, '\1' + "#{periodReplace}").gsub(/([\.\!\?])/, '\1' + "\n").each_line{|sentence|
         rtn << sentence.strip().gsub(/#{periodReplace}/, '.')
      }

      return rtn
   end
end
