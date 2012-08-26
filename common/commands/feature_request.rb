require 'net/http'
require 'net/https'

class FeatureRequest < Command
   def initialize
      super('FEATURE-REQUEST',
            'FEATURE-REQUEST <name/title of feature> ! <Description>',
            'Request a new feature for Clefable. Specifically it adds an issue to the github repository at https://github.com/eriq-augustine/clefable.',
            {
               :adminLevel => 10,
               :aliases => ['BUG', 'BUG-REPORT', 'FEATURE']
            })
   end

   def onCommand(responseInfo, args)
      args.strip!
      if (match = args.match(/(.*)!(.*)$/i))
         title = match[1].strip()
         description = "Reported by #{responseInfo.fromUser}.\n\n#{match[2].strip()}"

         begin
            http = Net::HTTP.new('api.github.com', 443)
            request = Net::HTTP::Post.new('/repos/eriq-augustine/clefable/issues' + "?access_token=#{OAUTH2_TOKEN}")
            body = {
            'title' => title,
            'body' => description,
            'labels' => [
            'FromIRC',
            ]
            }
            request.body = JSON.dump(body)
            http.use_ssl = true
            response = JSON.parse(http.request(request).body)
            responseInfo.respond('Created issue at: ' + response['html_url'])
         rescue Exception => ex
            log(ERROR, ex.message)
            responseInfo.respond('Sorry, there was a problem creating an issue.')
         end
      else
         responseInfo.respond("I don't understand. Try HELP FEATURE-REQUEST.")
      end
   end

   @@instance = FeatureRequest.new()
end
