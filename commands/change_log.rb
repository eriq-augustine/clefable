require './core/logging.rb'

require 'net/http'
require 'net/https'
require 'json'

#TODO: Cache results and somehow check laters version first

#https://api.github.com/repos/eriq-augustine/clefable/commits

class ChangeLog < Command
   def initialize
      super('CHANGE-LOG',
            'CHANGE-LOG [number of commits back]',
            'Get the commit messages for Clefable. The number of commits to look back defaults to 5.')
   end

   @@uri = URI('https://api.github.com/repos/eriq-augustine/clefable/commits' + "?access_token=#{OAUTH2_TOKEN}")
   @@defaultCommits = 5

   def onCommand(responseInfo, args)
      args.strip!

      if (args.length() == 0)
         numberOfCommits = @@defaultCommits
      elsif (match = args.match(/^\d+$/))
         numberOfCommits = args.to_i
      else
         responseInfo.respond("I don't understand that number, use an int.")
         return
      end

      begin
         http = Net::HTTP.new('api.github.com', 443)
         req = Net::HTTP::Get.new('/repos/eriq-augustine/clefable/commits' + "?access_token=#{OAUTH2_TOKEN}")
         http.use_ssl = true
         response = http.request(req)
         commits = JSON.parse(response.body)

         messages = Array.new()

         count = 0
         commits.each{|commit|
            message = "#{commit['commit']['author']['date']} -- #{commit['commit']['author']['name']}:" +
                      " #{commit['commit']['message']}"
            messages << message

            count += 1
            if (count >= numberOfCommits)
               break
            end
         }

         messages.each{|message|
            responseInfo.respond(message)
         }
      rescue Exception => ex
         log(ERROR, ex.message)
         responseInfo.respond('Sorry, there was a problem fetching the commit messages.')
      end
   end

   @@instance = ChangeLog.new()
end
