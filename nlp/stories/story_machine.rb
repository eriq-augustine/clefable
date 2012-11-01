# The Story Machine!
# This machine manages the story status.
# Every conversation gets a StoryMachine.
# Every story is a thread in the state machine.
#  From a normal state, there is a fairly high chance of moving to the next state of the story.
#  There is a small chance to move to a random state of any other story.
#  There is a smaller chance of staying in the current state.
# There is also a sleep state. Staying in the sleep state give the machine more "focus".
#  If the machine has little focus, then it has a greater chance of moving to the sleep state.
#  In the sleep state, there is a strong chance to stay in the sleep state bassed off of focus.
#  There is also a fair chance to move to the next proper chance.
#  There is a small chance to move to a random state.
class StoryMachine
 public
   def initialize(seed = nil)
      @random = seed ? Random.new(seed) : Random.new()
      @storyStates = []
      @sleepState = SleepState.new()
      @endState = EndState.new()
      @startState = nil

      firstStates = []

      allStories = StoryGenerator::genStories(15)
      Stories::getStoryKeys().each{|key|
         allStories << Stories::getStory(key)
      }

      allStories.each{|story|
         states = []

         (story.length() - 1).downto(0){|i|
            if (i == story.length() - 1)
               nextState = @endState
            else
               nextState = states[story.length() - i - 2]
            end

            newState = StoryState.new(story[i], nextState)
            states << newState
         }

         firstStates << states[-1]
         @storyStates.concat(states)
      }

      @startState = StartState.new(firstStates)
      @currentState = @startState
   end

   # Will return an empty string on an end state.
   def getNext()
      nextState = @currentState.nextState(@random, @startState, @endState, @sleepState, @storyStates)
      @currentState = nextState

      return @currentState.getText()
   end

   def reset()
      @currentState = @startState
      State::reset()
   end

   def end?
      return @currentState == @endState ||
             (@currentState.class == StoryMachine::StoryState && @currentState.nextStoryState == @endState)
   end

 private

   class State
      @@focus = 1.0

      def initialize(text)
         @text = text
      end

      def nextState(random, startState, endState, sleepState, storyStates)
         @@focus -= 0.05
         return nextStateImpl(random, startState, endState, sleepState, storyStates)
      end

      def getText()
         return @text
      end

      def self.reset()
         @@focus = 1.0
      end

    protected

      def setText(text)
         @text = text
      end
   end

   class StoryState < State
      attr_accessor :nextStoryState

      def initialize(text, nextState)
         super(text)
         @nextStoryState = nextState
      end

    protected

      def nextStateImpl(random, startState, endState, sleepState, storyStates)
         nextChance = 0.90
         stayChance = 0.05
         otherChance = 0.02

         # SLEEP TIME!
         if (random.rand() >= @@focus)
            sleepState.setNext(@nextStoryState)
            return sleepState
         end

         decision = random.rand()
         if (decision < nextChance)
            return @nextStoryState
         elsif (decision < (nextChance + stayChance))
            return self
         else
            # Random choice
            pick = storyStates.sample()
            while (pick != self)
               pick = storyStates.sample()
            end

            return pick
         end
      end
   end

   class StartState < State
      def initialize(firstStates)
         super('')
         @firstStates = firstStates
         @nextState = self
      end

    protected

      def nextStateImpl(random, startState, endState, sleepState, storyStates)
         return @firstStates.sample()
      end

      def setNext(state)
         @nextState = state
      end
   end

   class EndState < State
      def initialize()
         #super('Huh!')
         super('')
      end

    protected

      # Maybe emit that the story is done.
      def nextStateImpl(random, startState, endState, sleepState, storyStates)
         return startState.nextState(random, startState, endState, sleepState, storyStates)
      end
   end

   class SleepState < State
      def initialize()
         super('zzz')
         @nextState = self
         @zCount = 3
      end

      def setNext(state)
         @nextState = state
      end

    protected

      def nextStateImpl(random, startState, endState, sleepState, storyStates)
         @@focus += 0.2

         if (random.rand() > @@focus)
            @zCount += 1
            setText('z' * @zCount)
            return self
         end

         @zCount = 3
         setText('z' * @zCount)

         if (random.rand() > 0.3)
            return @nextState
         else
            return storyStates.sample()
         end
      end
   end
end
