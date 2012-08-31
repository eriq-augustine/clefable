# An implmentation of the Levenshtein edit-distance algorithm.

# This module include a cache to speed up comparisons.
module Levenshtein
   # { "#{word1}-#{word2}" => edit_dist }
   @@cache = Hash.new()

   # NOTE: This method is only when you suspect that |wordList| does not contain |word|.
   # The minimum distance and word between word and wordList.
   # Returns nil if no min word (does a greedy find).
   # Returns {:word => word, :dist => dist} on success.
   def minDistanceNoEquals(word, wordList)
      minWord = nil
      minDist = nil

      wordList.each{|otherWord|
         dist = editDistance(word, otherWord)

         # If the abosile min was found, return it.
         if (dist <= 1)
            return {:word => otherWord, :dist => dist}
         end

         if (!minWord || dist < minDist)
            minWord = otherWord
            minDist = dist
         end
      }

      return minWord ? {:word => minWord, :dist => minDist} : nil
   end

   def editDistance(word1, word2)
      cacheLookup = "#{word1}-#{word2}"
      rtn = @@cache[cacheLookup]

      if (!rtn)
         rtn = nonCacheEditDistance(word1, word2)
         @@cache[cacheLookup] = rtn
      end

      return rtn
   end

   # If MAX_LEVENSHTEIN_DISTANCE is set, then this method is short circuited
   #  if the value reaches above MAX_LEVENSHTEIN_DISTANCE
   def nonCacheEditDistance(word1, word2)
      if (defined?(MAX_LEVENSHTEIN_DISTANCE) && MAX_LEVENSHTEIN_DISTANCE)
         return nonCacheEditDistanceHelper(word1, word2, 0, MAX_LEVENSHTEIN_DISTANCE)
      else
         return nonCacheEditDistanceHelper(word1, word2, 0, 999)
      end
   end

   def nonCacheEditDistanceHelper(word1, word2, currentScore, maxScore)
      if (currentScore > maxScore)
         return currentScore
      end

      if (word1.empty?)
         return currentScore + word2.length()
      end

      if (word2.empty?)
         return currentScore + word1.length()
      end

      rtn = [
             nonCacheEditDistanceHelper(word1[1..-1], word2[1..-1], currentScore + (word1[0] == word2[0] ? 0 : 1), maxScore),
             nonCacheEditDistanceHelper(word1[1..-1], word2, currentScore + 1, maxScore),
             nonCacheEditDistanceHelper(word1, word2[1..-1], currentScore + 1, maxScore),
             maxScore + 1
            ].min

      return rtn
   end
end
