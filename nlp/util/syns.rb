require 'wordnet'
require 'set'

module Nlp
   # Looking up syns hurts. Cache plz.
   # {word => syns}
   @@synCache = {}
   # Cache for setSynOverlap().
   @@setCache = {}

   WordNet::WordNetDB.path = '/usr/local/WordNet-3.0'

   # This can cost a lot the first time, so don't do it for stupid words.
   # The syns will include the word itself.
   def self.syns(word)
      if (@@synCache.include?(word))
         return @@synCache[word]
      end

      rtn = Set.new()
      rtn << word.downcase.strip

      begin
         lemmas = WordNet::WordNetDB.find(word)
      rescue Exception => details
         log(ERROR, details.message())
         lemmas = []
      end

      lemmas.each{|lemma|
         begin
            synEntries = lemma.get_synsets()
         rescue Exception => details
            log(ERROR, details.message())
            synEntries = []
         end

         synEntries.each{|entry|
            entry.words.each{|syn|
               rtn << syn.downcase.strip
            }
         }
      }

      @@synCache[word] = rtn

      return rtn
   end

   def self.getSetSyns(someSet)
      if (@@setCache.include?(someSet))
         log(INFO, 'Set Syn Cache Hit')
         return @@setCache[someSet]
      end
      log(INFO, 'Set Syn Cache Miss')

      rtn = Set.new()

      someSet.each{|word|
         rtn.merge(syns(word))
      }

      @@setCache[someSet] = rtn

      return rtn
   end

   # Get how similar |needle| is to |haystack|.
   # This is a directed comparison (it is not the same one way as it is the other).
   # What percent of words from |needle| have syns in common with |haystack|.
   def self.setSynSim(needle, haystack)
      if (needle.size() == 0)
         return 0
      end

      haystackSyns = getSetSyns(haystack)
      count = 0

      needle.each{|word|
         if (haystackSyns.include?(word))
            count += 1
            break
         else
            needleSyns = syns(word)
            needleSyns.each{|syn|
               if (haystackSyns.include?(syn))
                  count += 1
                  break
               end
            }
         end
      }

      return count.to_f / needle.size()
   end
end

#needle = Set.new(['hound'])
#haystack = Set.new(['dog'])
#puts Nlp::setSynSim(needle, haystack)
