require 'digest/sha2'

def passHash(user, pass)
   return Digest::SHA2.new().update(user + '3.1415' + pass).to_s
end

# TODO: Breaks if Clefable does not know about the user (not in it's channles)
class Auth < Command
   include DB

   def initialize
      super('AUTH',
            'AUTH <pass phrase>',
            'Authenticate as a user. You should AUTH in a PM. You have to REGISTER before you can AUTH.')
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

   def onCommand(responseInfo, args, onConsole)
      if (responseInfo.target != IRC_NICK)
         responseInfo.respond('You must do this in a PM.')
         return
      end

      pass = args.strip

      hash = passHash(responseInfo.fromUser, pass)
      info = getInfo(responseInfo.fromUser)

      if (!info)
         responseInfo.respond('You are not in the system. Please REGISTER')
      elsif (info[:pass] == hash)
         responseInfo.server.getUsers()[responseInfo.fromUser].setAdmin(info[:level])
         responseInfo.server.getUsers()[responseInfo.fromUser].auth()
         responseInfo.respond('You are authenticated!')
      else
         responseInfo.respond('Bad Pass Phrase.')
      end
   end
end

class UserInfo < Command
   include DB

   def initialize
      super('USER-INFO',
            'USER-INFO [user]',
            'Get info about a user, or yourself if no user is given.')
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

   def onCommand(responseInfo, args, onConsole)
      user = args.strip

      if (user.length() == 0)
         user = responseInfo.fromUser
      end

      level = getLevel(user)

      if (!level)
         responseInfo.respond("Sorry, #{user} is not in my system.")
      else
         if (level == -1)
            responseInfo.respond("#{user} is a regular user.")
         else
            responseInfo.respond("#{user} an admin with level #{level} rights.")
         end
      end
   end
end

class Register < Command
   include DB

   def initialize
      super('REGISTER',
            'REGISTER <pass phrase>',
            'Register this nick into the Clefable system. Please REGISTER using a PM.')
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

   def onCommand(responseInfo, args, onConsole)
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
            "Register a new pass phrase for your nick. Must be AUTH'd first.")
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

   def onCommand(responseInfo, args, onConsole)
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

# TODO
# GRANT | REMOVE | MOD
class Admin < Command
end
