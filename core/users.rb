# TODO: Deal with ops properly.
#  Right now, ops are seen on user lists and accounted for, but nothing beyond that.
class User
   attr_reader :nick, :ops, :adminLevel, :email

   def initialize(nick, ops)
      @nick = nick
      @ops = ops
      @adminLevel = -1
      @auth = false
      @email = nil
   end

   def setAdmin(level)
      @adminLevel = level
   end

   def auth
      @auth = true
   end

   def setEmail(email)
      @email = email
   end

   def deauth
      @auth = false
      @adminLevel = -1
   end

   def isAuth?
      return @auth
   end

   # Can the user execute the command with |level|
   def canExecute?(level)
      # If there are no level requirements
      if (!level)
         return {:success => true}
      end

      if (!@auth)
         return {:success => false, :error => 'You need to be AUTH\'d.'}
      end
      
      if (level == -1)
         return {:success => false, :error => "You need to be an admin with level #{level} rights to execute this command."}
      end

      if (level < @adminLevel)
         return {:success => false, :error => "You need an admin level of #{level}, you only have a level of #{@adminLevel}."}
      end

      return {:success => true}
   end
end

# Add the console user.
CONSOLE_USER = User.new(CONSOLE, false)
CONSOLE_USER.auth
CONSOLE_USER.setAdmin(0)
