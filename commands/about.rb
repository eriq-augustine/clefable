class About < Command
   include TextStyle

   def initialize
      super('ABOUT',
            'ABOUT [NAME | SOURCE | USAGE]',
            'Learn about Clefable.')
      @basicStr = "#{pink('Clefable')} is a chat bot started by ^Eriq"
      @nameStr = "The name \"#{pink('Clefable')}\" holds no special meaning." +
               ' A random number was generated, and that pokemon was chosen.'
      @sourceStr = "#{pink('Clefable')} was written all in Ruby and you can get the source at:" +
               ' https://github.com/eriq-augustine/clefable'
      @usageStr = "You can invoke commands by using '#{IRC_NICK}: <command>', '#{SHORT_NICK}: <command>', or '#{TRIGGER}<command>'. When PMing, you can just enter commands."
      @caseStr = "Case is generally ignored, but no promises."
   end

   @@instance = About.new()

   def onCommand(responseInfo, args)
      args.upcase!

      if (args == 'NAME')
         responseInfo.respond(@nameStr)
      elsif (args == 'SOURCE')
         responseInfo.respond(@sourceStr)
      elsif (args == 'USAGE')
         responseInfo.respond(@usageStr)
         responseInfo.respond(@caseStr)
      else
         responseInfo.respond(@basicStr)
         responseInfo.respond(@usageStr)
         responseInfo.respond(@caseStr)
         responseInfo.respond(@nameStr)
         responseInfo.respond(@sourceStr)
      end
   end
end
