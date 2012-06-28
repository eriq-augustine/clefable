require 'digest/sha2'

def passHash(user, pass)
   return Digest::SHA2.new().update(user + '3.1415' + pass).to_s
end

class Auth < Command
   include DB

   def initialize
      super('AUTH',
            'AUTH <pass phrase>',
            'Authenticate as a user. You should AUTH in a PM. You have to REGISTER before you can AUTH.',
            {:skipLog => true})
   end

   @@instance = Auth.new()

   def getInfo(fromUser)
      res = db.query("SELECT pass, `level`" +
                     " FROM #{ADMIN_TABLE}" +
                     " WHERE `user` = '#{escape(fromUser)}'")
      if (res.num_rows() == 0)
         return nil
      else
         row = res.fetch_row()
         return {:pass => row[0], :level => row[1].to_i}
      end
   end

   def onCommand(responseInfo, args)
      if (responseInfo.target != IRC_NICK)
         responseInfo.respond('You must do this in a PM.')
         return
      end

      userInfo = responseInfo.server.getUsers()[responseInfo.fromUser]
      if (!userInfo)
         responseInfo.respond("I don't know if you are actually on. If you are real, leave and rejoin.")
         return
      end

      pass = args.strip

      if (pass.length() == 0)
         responseInfo.respond("USAGE: #{@usage}")
         return
      end

      hash = passHash(responseInfo.fromUser, pass)
      info = getInfo(responseInfo.fromUser)

      if (!info)
         responseInfo.respond('You are not in the system. Please REGISTER')
      elsif (info[:pass] == hash)
         userInfo.setAdmin(info[:level])
         userInfo.auth()
         responseInfo.respond('You are now authenticated!')
      else
         responseInfo.respond('Bad Pass Phrase.')
      end
   end
end

class Deauth < Command
   include DB

   def initialize
      super('DEAUTH',
            'DEAUTH',
            'Deauthenticate from the Clefable system.')
   end

   @@instance = Deauth.new()

   def onCommand(responseInfo, args)
      userInfo = responseInfo.server.getUsers()[responseInfo.fromUser]
      if (userInfo)
         userInfo.deauth
      end

      responseInfo.respond("You are DEAUTH'd.")
   end
end


class UserInfo < Command
   include DB

   def initialize
      super('USER-INFO',
            'USER-INFO [[^]user]',
            'Get info about a user, or yourself if no user is given.',
            {:aliases => ['WHO', 'WHOIS']})
   end

   @@instance = UserInfo.new()

   def getLevel(user)
      res = db.query("SELECT `level`" +
                     " FROM #{ADMIN_TABLE}" +
                     " WHERE `user` = '#{escape(user)}'")
      if (res.num_rows() == 0)
         return nil
      else
         row = res.fetch_row()
         return row[0].to_i
      end
   end

   def onCommand(responseInfo, args)
      user = args.strip.sub(/^\^/, '')

      if (user.length() == 0)
         user = responseInfo.fromUser
      end

      level = getLevel(user)

      if (!level)
         responseInfo.respond("Sorry, ^#{user} is not in my system.")
      else
         if (level == -1)
            responseInfo.respond("^#{user} is a regular user.")
         else
            responseInfo.respond("^#{user} is an admin with level #{level} rights.")
         end
      end
   end
end

class Register < Command
   include DB

   def initialize
      super('REGISTER',
            'REGISTER <pass phrase>',
            'Register this nick into the Clefable system. Please REGISTER using a PM.',
            {:skipLog => true})
   end

   @@instance = Register.new()

   def hasUser(user)
      res = db.query("SELECT * FROM #{ADMIN_TABLE} WHERE `user` = '#{escape(user)}'")
      return (res.num_rows() == 1)
   end

   def insertUser(user, pass)
      hash = passHash(user, pass)
      db.query("INSERT INTO #{ADMIN_TABLE} VALUES ('#{escape(user)}', '#{hash}', -1)")
      return true
   end

   def onCommand(responseInfo, args)
      if (responseInfo.target != IRC_NICK)
         responseInfo.respond('You must do this in a PM.')
         return
      end

      pass = args.strip

      if (pass.length() == 0)
         responseInfo.respond('Cannot use an empty pass phrase.') 
      else
         if (hasUser(responseInfo.fromUser))
            responseInfo.respond('You are already in the system.')
         else
            if (insertUser(responseInfo.fromUser, pass))
               responseInfo.respond('Congrats! You got registered.')
            else
               responseInfo.respond('Sorry, there was a problem registering you.')
            end
         end
      end
   end
end

class Pass < Command
   include DB   
   
   def initialize
      super('PASS',
            'PASS <new pass phrase>',
            "Register a new pass phrase for your nick. Must be AUTH'd first.",
            {:skipLog => true})
   end

   @@instance = Pass.new()

   def hasUser(user)
      res = db.query("SELECT * FROM #{ADMIN_TABLE} WHERE `user` = '#{escape(user)}'")
      return (res.num_rows() == 1)
   end

   def updatePass(user, pass)
      hash = passHash(user, pass)
      db.query("UPDATE #{ADMIN_TABLE} SET pass = '#{hash}' WHERE `user` = '#{escape(user)}'")
      return true
   end

   def onCommand(responseInfo, args)
      if (responseInfo.target != IRC_NICK)
         responseInfo.respond('You must do this in a PM.')
         return
      end

      pass = args.strip

      if (pass.length() == 0)
         responseInfo.respond('Cannot use an empty pass phrase.') 
      else
         if (!hasUser(responseInfo.fromUser))
            responseInfo.respond('You are not in the system.')
         elsif (!responseInfo.server.getUsers()[responseInfo.fromUser].auth())
            responseInfo.respond("You are not AUTH'd.")
         else
            if (updatePass(responseInfo.fromUser, pass))
               responseInfo.respond('Pass phrase updated.')
            else
               responseInfo.respond('Sorry, there was a problem updating your pass phrase.')
            end
         end
      end
   end
end

# GRANT | REMOVE | MOD
class Admin < Command
   include DB   
   
   MAX_LEVEL = 999

   def initialize
      super('ADMIN',
            "ADMIN GRANT [^]<user> <level>; " + 
            "ADMIN REMOVE [^]<user>; " + 
            "ADMIN MOD [^]<user> <new level>",
            "GRANT a user admin rights. REMOVE a user's admin rights. MOD a user's admin rights." +
            " Admins can GRANT other admins to as high as their own level, and can MOD/REMOVE admins below their level.",
            {:adminLevel => MAX_LEVEL})
   end

   @@instance = Admin.new()

   def modLevel(user, level)
      db.query("UPDATE #{ADMIN_TABLE} SET `level` = #{level} WHERE `user` = '#{escape(user)}'")
   end

   def getLevel(user)
      res = db.query("SELECT `level`" +
                     " FROM #{ADMIN_TABLE}" +
                     " WHERE `user` = '#{escape(user)}'")
      if (res.num_rows() == 0)
         return nil
      else
         row = res.fetch_row()
         return row[0].to_i
      end
   end
    
   def handleRemove(responseInfo, users, requestUser, removeUser)
      actualLevel = getLevel(removeUser)

      if (!actualLevel)
         responseInfo.respond("#{removeUser} is not in the system and therefore not an admin.")
         return false
      end

      if (actualLevel == -1)
         responseInfo.respond("#{removeUser} is not an admin.")
         return false
      end

      if (actualLevel <= requestUser.adminLevel)
         responseInfo.respond("You cannot remove an admin with equal or more power than yourself.")
         return false
      end

      modLevel(removeUser, -1)

      # Update runtime information
      if (users.has_key?(removeUser))
         users[removeUser].setAdmin(-1)
      end

      return true
   end

   def handleMod(responseInfo, users, requestUser, modUser, requestLevel)
      actualLevel = getLevel(modUser)

      if (!actualLevel)
         responseInfo.respond("#{modUser} is not in the system and therefore not an admin.")
         return false
      end

      if (actualLevel == -1)
         responseInfo.respond("#{modUser} is not an admin.")
         return false
      end

      if (requestLevel < 0 || requestLevel > MAX_LEVEL)
         responseInfo.respond("#{requestLevel} is not a valid level for an admin.")
         return false
      end
      
      if (requestLevel < requestUser.adminLevel)
         responseInfo.respond("You cannot create an admin with more power than yourself.")
         return false
      end

      if (actualLevel <= requestUser.adminLevel)
         responseInfo.respond("You cannot mod an admin with equal or more power than yourself.")
         return false
      end

      modLevel(modUser, requestLevel)

      # Update runtime information
      if (users.has_key?(modUser))
         users[modUser].setAdmin(requestLevel)
      end

      return true
   end
  
   def handleGrant(responseInfo, users, requestUser, grantUser, requestLevel)
      actualLevel = getLevel(grantUser)

      if (!actualLevel)
         responseInfo.respond("#{grantUser} is not in the system. They have to REGISTER before becoming an admin.")
         return false
      end

      if (actualLevel != -1)
         responseInfo.respond("#{grantUser} is already an admin with level #{actualLevel}. Try ADMIN MOD.")
         return false
      end

      if (requestLevel < 0 || requestLevel > MAX_LEVEL)
         responseInfo.respond("#{requestLevel} is not a valid level for an admin.")
         return false
      end
      
      if (requestLevel < requestUser.adminLevel)
         responseInfo.respond("You cannot add an admin with more power than yourself.")
         return false
      end

      modLevel(grantUser, requestLevel)

      # Update runtime information
      if (users.has_key?(grantUser))
         users[grantUser].setAdmin(requestLevel)
      end

      return true
   end

   def onCommand(responseInfo, args)
      users = responseInfo.server.getUsers()

      if (!users.has_key?(responseInfo.fromUser))
         responseInfo.respond('You are not loged into the system.')
      end

      requestUser = users[responseInfo.fromUser]

      if (!requestUser.isAuth?)
         responseInfo.respond("You must be AUTH'd first.")
         return
      end

      if (requestUser.adminLevel == -1)
         responseInfo.respond("You are not an admin. Only admins can add admins.")
         return
      end

      args.strip!
      if (match = args.match(/^GRANT\s+(\S+)\s+(\d+)/i))
         user = match[1].sub(/^\^/, '')
         level = match[2].to_i
         if(handleGrant(responseInfo, users, requestUser, user, level))
            responseInfo.respond("^#{user} has sucessfully become and admin with level #{level} rights.")
         end
      elsif (match = args.match(/^REMOVE\s+(\S+)/i))
         user = match[1].sub(/^\^/, '')
         if(handleRemove(responseInfo, users, requestUser, user))
            responseInfo.respond("^#{match[1]} has sucessfully been striped of all admin rights.")
         end
      elsif (match = args.match(/^MOD\s+(\S+)\s+(\d+)/i))
         user = match[1].sub(/^\^/, '')
         level = match[2].to_i
         if(handleMod(responseInfo, users, requestUser, user, level))
            responseInfo.respond("^#{user} has sucessfully had their rights changed to #{level}.")
         end
      else
         responseInfo.respond("I don't understand. Try: HELP ADMIN")
      end
   end
end
