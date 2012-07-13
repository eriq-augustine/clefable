require 'time'

module TimeConversions
   # Explode a number of seconds into a hash with:
   #  :days, :hours, :mins, :secs
   def explodeSecs(secs)
      days = secs / 86400
      secs -= days * 86400

      hours = secs / 3600
      secs -= hours * 3600

      mins = secs / 60
      secs -= mins * 60

      return {:days => days, :hours => hours,
              :mins => mins, :secs => secs}
   end

   def secsToExplodedString(secs)
      explode = explodeSecs(secs)
      rtn = ''

      if ((days = explode[:days]) != 0)
         rtn += "#{days} day"
         if (days > 1)
            rtn += 's'
         end
      end

      if ((hours = explode[:hours]) != 0)
         if (rtn != '')
            rtn += ', '
         end

         rtn += "#{hours} hour"
         if (hours > 1)
            rtn += 's'
         end
      end

      if ((mins = explode[:mins]) != 0)
         if (rtn != '')
            rtn += ', '
         end

         rtn += "#{mins} minute"
         if (mins > 1)
            rtn += 's'
         end
      end

      if ((secs = explode[:secs]) != 0)
         if (rtn != '')
            rtn += ', '
         end

         rtn += "#{secs} second"
         if (secs > 1)
            rtn += 's'
         end
      end

      return rtn
   end
end
