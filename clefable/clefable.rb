class Clefable < Bot
   include TextStyle

 public

   attr_reader :commitFetcher

   # In general, throttled is ignored because of it's varied nature.
   def updateTreeStatus(status, message)
      if (@currentTreeStatus == status)
         return
      end

      # Only try to tell people if the tree goes directly from open to closed.
      if (@currentTreeStatus == TreeStatus::TREE_STATUS_OPEN &&
          status == TreeStatus::TREE_STATUS_CLOSED)
         # Look for emails of possible tree breakers.
         message.scan(/\w+@\w+\.\w+/).each{|email|
            if (@revEmailMap.has_key?(email) && @users.has_key?(@revEmailMap[email]))
               chat(@revEmailMap[email], "You may have broken the tree: #{message}")

               # TODO(eriq): Remove this log when you are sure it works
               log(DEBUG, "#{email} (#{@revEmailMap[email]}) may have broken the tree: #{message}")
            end
         }
      end

      @currentTreeStatus = status
   end

 protected

   def initialize()
      super()

      @currentTreeStatus = TreeStatus::TREE_STATUS_UNKNOWN
      TreeStatus::getTreeStatus()
      registerPeriodicAction(lambda{ TreeStatus::getTreeStatus() })

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
               # It is common practice to append '_' or '-' to your nick if it is taken.
               # kalman likes to put numbers!
               realNick = nick.sub(/(\d+)|([_-]+)$/, '')
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
