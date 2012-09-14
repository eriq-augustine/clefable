class Clefable < Bot
   include TextStyle

 public

   attr_reader :commitFetcher

 protected

   def initialize()
      super()

      @commitFetcher = CommitFetcher.new()
      # Do the first update quietly
      @commitFetcher.updateCommits()

      registerPeriodicAction(lambda{ checkForCommits() })
   end

   def checkForCommits
      # Check for new commits
      newCommits = @commitFetcher.updateCommits()
      if (!newCommits.empty?)
         #Check all the channels for the committers
         notifyAboutCommits(newCommits)
      end
   end

 private

   def notifyAboutCommits(newCommits)
      newCommits.each{|commit|
         committer = commit[:author].sub(/@.*$/, '')

         @channels.each_pair{|channel, users|
            broadcast = false
            users.each_key{|nick|
               #It is common practice to append '_' or '-' to your nick if it is taken.
               realNick = nick.sub(/[_-]+$/, '')
               # TODO: Use the registered emails instead of or in addition to the map
               if (committer == realNick ||
                   (@emailMap[realNick] && @emailMap[realNick][:email] == committer) ||
                   (@emailMap[nick] && @emailMap[nick][:email] == committer))
                  broadcast = true
                  break
               end
            }

            if (broadcast)
               chat(channel, "#{purple("http://crrev.com/#{commit[:rev]}")}" +
                             " ^#{commit[:author]} -- #{commit[:summary]}")
            end
         }
      }
   end
end
