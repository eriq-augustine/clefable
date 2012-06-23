require 'net/http'
require 'json'
require 'rexml/document'
require 'time'

# This should be loaded by core, but require it here just in case order is wrong
require './util/db.rb'

#'http://git.chromium.org/gitweb/?p=chromium/src.git;a=log'

class CommitFetcher
   include REXML
   include DB

   def initialize()
      @lastCommit = getLastCommit()
   end

   # Should be constant, but using class instance instead to avoid redef warning.
   @@commitsUri = URI('http://git.chromium.org/gitweb/?p=chromium/src.git;a=log')
   
   def getLastCommit()
      rtn = 0

      res = query("SELECT MAX(rev) FROM #{COMMIT_TABLE}")

      if (res && res.num_rows() == 1)
         rtn = res.fetch_row()[0].to_i
      end

      return rtn
   end

   def insertCommits(commits)
      if (commits.empty?)
         return
      end

      @lastCommit = commits[0][:rev]
      insertStr = "INSERT IGNORE INTO #{COMMIT_TABLE} (rev, author, time, summary) VALUES "

      commits.each{|commit|
         insertStr += "(#{commit[:rev]}," +
                      " '#{escape(commit[:author])}'," +
                      " #{commit[:time].to_i}," +
                      " '#{escape(commit[:summary])}'), "
      }

      update(insertStr.sub(/, $/, ''))
   end

   # returns the new commits
   def updateCommits
      commits = Array.new()

      begin
         response = Net::HTTP.get(@@commitsUri)
         xmlDoc = Document.new(response)

         commitInfo = nil
         xmlDoc.elements.each('html/body/div') {|ele|
            className = ele.attribute('class').value
            if (className == 'title_text')
               commitInfo = {}
               authorInfo = ele.get_elements('span')[0].elements.to_a
               if (authorInfo[0].text == 'gitdeps')
                  next
               end
               commitInfo[:author] = authorInfo[0].text
               commitInfo[:time] = Time.parse(authorInfo[1].text).to_i
            elsif (className == 'log_body')
               if (commitInfo)
                  count = 0
                  ele.to_s.gsub(/&nbsp;/, ' ').gsub(/\<br\s*\/\>/, '').each_line{|line|
                     if (count == 1)
                        commitInfo[:summary] = line.strip
                     elsif (match = line.match(/chromium\.org\/chrome\/trunk\/src@(\d+)/))
                           commitInfo[:rev] = match[1].to_i

                           if (commitInfo[:rev] <= @lastCommit)
         commits.each{|commit|
            puts commit
         }
                              insertCommits(commits)
                              return commits
                           end

                           commits << commitInfo
                           commitInfo = nil
                     end
                     count += 1
                  }
               end
            end
         }

         insertCommits(commits)
         
         commits.each{|commit|
            puts commit
         }
      rescue Exception => ex
         puts ex.message  
         puts ex.backtrace.inspect 
         message = 'Sorry, there was a problem fetching the last commits.'
      end
      
      return commits
   end
end
