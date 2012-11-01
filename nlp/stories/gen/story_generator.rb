# Generate stories.

# Stories come in four parts:
#  The time of the story: "Back in my day..."
#  The lack of something: "We didn't have pants"
#  The hardship:          "Had to use shirts on our legs"
#  The resolution:        "We called them 'Leg Mittens'"
#
# First pass is a naive combination.
class StoryGenerator
   extend ClassUtil

   # A story will be an array of strings.
   def self.genStories(numStories = 5)
      stories = []

      for i in 0...5
         story = []

         story << @@times.sample()
         story << @@lacks.sample()
         story << @@hardships.sample()
         story << @@resolutions.sample()

         stories << story
      end

      return stories
   end

 private
   RELOADABLE_CLASS_VARIABLE('@@times', [])
   RELOADABLE_CLASS_VARIABLE('@@lacks', [])
   RELOADABLE_CLASS_VARIABLE('@@hardships', [])
   RELOADABLE_CLASS_VARIABLE('@@resolutions', [])

   def self.init()
      loadFile(@@times, './nlp/stories/gen/times.part')
      loadFile(@@lacks, './nlp/stories/gen/lacks.part')
      loadFile(@@hardships, './nlp/stories/gen/hardships.part')
      loadFile(@@resolutions, './nlp/stories/gen/resolutions.part')
   end

   def self.loadFile(list, filename)
      file = File.open(filename, 'r')

      file.each{|line|
         list << line.strip()
      }

      file.close()
   end

   # Read the partials
   init()
end
