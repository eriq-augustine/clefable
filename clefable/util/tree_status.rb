require 'net/http'

#'http://chromium-status.appspot.com/current?format=json'

module TreeStatus
   extend ClassUtil

   # ENUM for tree status
   TREE_STATUS_UNKNOWN = -1
   TREE_STATUS_OPEN = 0
   TREE_STATUS_THROTTLED = 1
   TREE_STATUS_CLOSED = 2

   RELOADABLE_CONSTANT('STATUS_URI', URI('http://chromium-status.appspot.com/current?format=json'))

   def self.getTreeStatus()
      status = TREE_STATUS_UNKNOWN
      message = ''

      begin
         jsonStatus = JSON.parse(Net::HTTP.get(STATUS_URI))

         state = "#{jsonStatus['general_state'].strip.upcase}"
         message = jsonStatus['message']
         if (state == 'OPEN')
            status = TREE_STATUS_OPEN
         elsif (state == 'CLOSED')
            status = TREE_STATUS_CLOSED
         elsif (state == 'THROTTLED')
            status = TREE_STATUS_THROTTLED
         end
      rescue Exception => ex
         log(ERROR, ex.message)
         log(ERROR, ex.backtrace.inspect)
      end

      Clefable::instance.updateTreeStatus(status, message)
      return status, message
   end
end
