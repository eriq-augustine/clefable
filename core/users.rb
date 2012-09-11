# TODO: Deal with ops properly.
#  Right now, ops are seen on user lists and accounted for, but nothing beyond that.
class User
   include DB

   attr_reader :nick, :ops, :adminLevel, :email
   attr_accessor :address, :extraInfo, :geo

   def initialize(nick, ops)
      @nick = nick
      @ops = ops
      @adminLevel = -1
      @auth = false
      @email = nil

      @address = nil
      @extraInfo = nil
      # A hash
      @geo = nil

      # This will be lazily retrieved from the db.
      @executable = nil
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

   # Is this user allowed to execute commands at all?
   def canExecute?()
      if (@executable == nil)
         res = dbQuery("SELECT executable FROM #{USERS_TABLE} where `user` = '#{@nick}'")

         if (!res || res.num_rows() > 1)
            log(ERROR, "There was some error getting #{@nick}'s executable.")
            return false
         end

         # This user does not have an entry, let them execute.
         if (res.num_rows() == 0)
            @executable = true
         else
            @executable = res.fetch_row()[0].to_i == 1
         end
      end

      return @executable
   end

   # Can the user execute the command with |level|
   def canExecuteAtLevel?(level)
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
