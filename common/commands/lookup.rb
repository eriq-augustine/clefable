class Lookup < Command
   def initialize
      super('LOOKUP',
            'LOOKUP -n [^]<nick>',
            'Try and discover someone\'s identity. -n (nice) don\'t expose full information.',
            {:adminLevel => 0})
   end

   @@instance = Lookup.new()

   def onCommand(responseInfo, args)
      nick = args.strip.sub(/^\^/, '')
      if (nick == 'frewsxcv')
         responseInfo.respond("^#{nick}: Corey F. -- Org: Cal Poly, Focus: SE")
      else
         responseInfo.respond("I can't find any info on ^#{nick}.")
      end
   end
end
