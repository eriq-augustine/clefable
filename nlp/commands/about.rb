class About < Command
   def initialize
      super('ABOUT',
            'ABOUT',
            "Learn about #{IRC_NICK}.")
   end

   @@instance = About.new()

   def onCommand(responseInfo, args)
      responseInfo.respond("I am Eriq's NLP bot. My full name is 'Princess Rainicorn'. You can check out my source at: " +
                           'https://github.com/eriq-augustine/clefable/tree/nlp')
   end
end
