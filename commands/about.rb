class About < Command
   def initialize
      super('ABOUT',
            'ABOUT [NAME | SOURCE | USAGE]',
            'Learn about Clefable.')
   end

   @@instance = About.new()
   @@basic = 'Clefable is a chat bot started by ^Eriq'
   @@name = 'The name "Clefable" holds no special meaning.' +
            ' A random number was generated, and that pokemon was chosen.'
   @@source = 'Clefable was written all in Ruby and you can get the source at:' +
              ' https://github.com/eriq-augustine/clefable'
   @@usage = "You can invoke commands by using '#{IRC_NICK}: <command>', '#{SHORT_NICK}: <command>', or '#{TRIGGER}<command>'. When PMing, you can just enter commands."
   @@case = "Case is generally ignored, but no promises."


   def onCommand(responseInfo, args)
      args.upcase!

      if (args == 'NAME')
         responseInfo.respond(@@name)
      elsif (args == 'SOURCE')
         responseInfo.respond(@@source)
      elsif (args == 'USAGE')
         responseInfo.respond(@@usage)
         responseInfo.respond(@@case)
      else
         responseInfo.respond(@@basic)
         responseInfo.respond(@@usage)
         responseInfo.respond(@@case)
         responseInfo.respond(@@name)
         responseInfo.respond(@@source)
      end
   end
end
