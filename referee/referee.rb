class Referee < Bot
   def initialize()
      super()
   end

   def self.instance
      if (!defined?(@@instance) || !@@instance)
         @@instance = Referee.new()
      end

      return @@instance
   end
end
