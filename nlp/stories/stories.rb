# Hold all the stories!
# Stories are held in .story files, but internally, they are an array of scentences.
#  These are just text files.
#  The key for a story is the base file name,
module Stories
   extend ClassUtil

   RELOADABLE_CLASS_VARIABLE('@@stories', Hash.new())

   def self.getStoryKeys()
      return @@stories.keys()
   end

   # Returns the story associated with the given key as an array of sentences.
   def self.getStory(key)
      return @@stories[key]
   end

   def self.addStory(key, text)
      @@stories[key] = normalizeStory(text)
   end

 private

   # Naive Split
   # Fuck it, 3 part replace.
   def self.normalizeStory(text)
      rtn = []

      periodReplace = '@@'
      periodRegex = /((?:P)|(?:S)|(?:Mr)|(?:Mrs)|(?:Ms)|(?:Mme)|(?:Sta)|(?:Sr)|(?:Sra)|(?:Dr))\./

      text.gsub(/[\s\n]+/, ' ').strip().gsub(periodRegex, '\1' + "#{periodReplace}").gsub(/([\.\!\?])/, '\1' + "\n").each_line{|sentence|
         rtn << sentence.strip().gsub(/#{periodReplace}/, '.')
      }

      puts rtn
      puts ''

      return rtn
   end
end
