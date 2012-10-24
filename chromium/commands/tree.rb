class Tree < Command
   include TextStyle

   def initialize
      super('TREE',
            'TREE',
            'Check the tree status.',
            {:aliases => ['TREE?']})
   end

   @@instance = Tree.new()

   def onCommand(responseInfo, args)
      status, message = TreeStatus::getTreeStatus()

      if (status != TreeStatus::TREE_STATUS_UNKNOWN)
         if (status == TreeStatus::TREE_STATUS_OPEN)
            state = green("OPEN")
         elsif (status == TreeStatus::TREE_STATUS_CLOSED)
            state = red("CLOSED")
         elsif (status == TreeStatus::TREE_STATUS_THROTTLED)
            state = yellow("THROTTLED")
         end

         message = "#{bold(state)} -- #{message}"
      else
         message = 'Sorry, there was a problem fetching the tree status.'
      end

      responseInfo.respond(message)
   end
end
