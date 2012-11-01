Loader::loadDir('./nlp/stories/gen')
Loader::loadAllInDir('./nlp/stories')

# Load all the stories into the Stories module
Dir["./nlp/stories/*.story"].each{|file|
   lines = IO.readlines(file)
   Stories.addStory(file.sub(/\/story$/, ''), lines.join(' '))
}
