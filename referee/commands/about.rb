class About < Command
   include TextStyle

   def initialize
      super('ABOUT',
            'ABOUT [NAME | SOURCE | USAGE]',
            'Learn about Referee.')
      @basicStr = "TODO: desc"
      @nameStr = "TODO: desc"
      @sourceStr = "TODO: desc"
      @usageStr = "TODO: desc"
      @caseStr = "TODO: desc"
   end

   @@instance = About.new()

   def onCommand(responseInfo, args)
      args.upcase!

      # TODO: Write real descriptions.

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
