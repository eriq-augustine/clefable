class LastCommit < Command
   include DB
   include TextStyle

   def initialize
      super('LAST-COMMIT',
            'LAST-COMMIT [<N>]',
            'Get the last N commits. N defaults to 1.',
            {:aliases => ['LAST-COMMITS']})
   end

   @@instance = LastCommit.new()

   def getCommits(n)
      rtn = Array.new()
      res = query("SELECT rev, author, time, summary FROM #{COMMIT_TABLE}" + 
                  " ORDER BY rev DESC LIMIT #{n}")
      if (res)
         res.each{|row|
            rtn << {:rev => row[0].to_i, :author => row[1],
                    :time => row[2].to_i, :summary => row[3]}
         }
      end

      return rtn
   end

   def onCommand(responseInfo, args)
      if (match = args.match(/\s*(\d*)\s*/))
         if (match[1].length == 0)
            n = 1
         else
            n = match[1].to_i
         end

         commits = getCommits(n)

         if (commits.size() == 0)
            responseInfo.respond('No results.')
         else
            commits.each{|commit|
               responseInfo.respond("#{purple("http://crrev.com/#{commit[:rev]}")} (#{Time.at(commit[:time])}) ^#{commit[:author]} -- #{commit[:summary]}")
            }
         end
      else
         responseInfo.respond('I don\'t understand that number, use an int.')
      end
   end
end
