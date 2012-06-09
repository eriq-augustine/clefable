module RateLimit
   def calcSleepTime(numMessages)
      if (numMessages >= 50)
         return 1
      end

      return 0.2 + 0.75 * (numMessages / 50.0)
   end
end
