require 'net/http'

# http://api.ipinfodb.com/v3/ip-city/?key=<KEY>&ip=<IP>&format=json

class Geoip < Command
   def initialize
      super('GEO-IP',
            'GEO-IP [[^]user]',
            'Attempt to lookup a user\'s geo location.',
            {:aliases => ['GEOIP', 'GEO']})

      # { target_nick => [ responseInfo to respond to ] }
      @pendingWhois = Hash.new{|hash, key| hash[key] = Array.new()}
   end

   @@instance = Geoip.new()

   def getGeoInfo(ip)
      rtn = nil
      uri = URI("http://api.ipinfodb.com/v3/ip-city/?key=#{IPINFODB_KEY}&ip=#{ip}&format=json")

      begin
         info = JSON.parse(Net::HTTP.get(uri))
         if (info['statusCode'] == 'OK')
            rtn = {:country => info['countryName'],
                   :region => info['regionName'],
                   :city => info['cityName'],
                   :latitude => info['latitude'],
                   :longitude => info['longitude']}
         end
      rescue Exception => ex
         log(ERROR, ex.message)
         log(ERROR, ex.backtrace.inspect)
      end

      return rtn
   end

   def formatGeoString(nick, user)
      return "^#{nick} -- #{user.geo[:country]}, #{user.geo[:region]}," +
             " #{user.geo[:city]}, (#{user.geo[:latitude]}, #{user.geo[:longitude]})"
   end

   def onCommand(responseInfo, args)
      if (!match = args.strip.match(/^\^?(\S+)$/))
         responseInfo.respond("Bad syntax, try HELP GEO-IP.")
         return
      end

      nick = match[1]
      user = responseInfo.server.getUser(nick)

      if (!user)
         responseInfo.respond("Sorry, I do not know about ^#{nick}.")
         return
      end

      if (!user.address)
         # No address yet, get it.
         @pendingWhois[nick] << responseInfo
         responseInfo.server.whois(nick)
         return
      end

      if (user.geo)
         responseInfo.respond(formatGeoString(nick, user))
         return
      else
         geo = getGeoInfo(user.address)
         if (!geo)
            responseInfo.respond("Sorry, cannot get geo information for ^#{user}.")
            return
         else
            user.geo = geo
            responseInfo.respond(formatGeoString(nick, user))
            return
         end
      end
   end

   def onUserInfo(nick, infoType, info)
      if (infoType != 'WHOIS')
         return
      end

      if (@pendingWhois.has_key?(nick))
         user = Bot::instance.getUser(nick)
         if (!user)
            @pendingWhois[nick].each{|responseInfo|
               responseInfo.respond("Sorry, I do not know about ^#{nick}.")
            }
         else
            geo = getGeoInfo(user.address)
            response = ''

            if (!geo)
               response = "Sorry, cannot get geo information for ^#{user}."
            else
               user.geo = geo
               response = formatGeoString(nick, user)
            end

            @pendingWhois[nick].each{|responseInfo|
               responseInfo.respond(response)
            }
         end
         @pendingWhois.delete(nick)
      end
   end
end
