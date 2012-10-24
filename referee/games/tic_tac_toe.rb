class TicTacToe < Game
   EMPTY = 0
   PLAYER1 = 1
   PLAYER2 = -1

   def initialize(startingPlayer, pendingPlayer)
      super(startingPlayer, pendingPlayer)

      @board = [[EMPTY, EMPTY, EMPTY], 
                [EMPTY, EMPTY, EMPTY], 
                [EMPTY, EMPTY, EMPTY]] 

      @turnCounter = 1
   end

   def otherPlayerToken
      if (@turnCounter % 2 == 1)
         return PLAYER2
      else
         return PLAYER1
      end
   end

   def otherPlayerName
      if (@turnCounter % 2 == 1)
         return @player2
      else
         return @player1
      end
   end


   def currentPlayerToken
      if (@turnCounter % 2 == 1)
         return PLAYER1
      else
         return PLAYER2
      end
   end

   def currentPlayerName
      if (@turnCounter % 2 == 1)
         return @player1
      else
         return @player2
      end
   end

   def takeTurn(responseInfo, args)
      if (responseInfo.fromUser != currentPlayerName())
         responseInfo.respond("^#{responseInfo.fromUser}: It is not your turn.")
         return false
      end

      if (match = args.strip.match(/\(?\s*(\d)\s*,?\s*(\d)\s*\)?/))
         row = match[1].to_i
         col = match[2].to_i

         if (row < 0 || row > 2 || col < 0 || col > 2)
            responseInfo.respond("(#{row},#{col}) is not a valid location." +
                                  " The valid range is (0,0) to (2,2).")
            return false
         end

         if (@board[row][col] != EMPTY)
            responseInfo.respond("(#{row},#{col}) is already taken. Choose another spot.")
            return false
         end

         @board[row][col] = currentPlayerToken()

         if (gameOver?())
            responseInfo.respond("Congrats #{responseInfo.fromUser}! You Won!")
            @gameOverStatus = (@turnCounter % 2 == 1) ? GAME_OVER_PLAYER1 : GAME_OVER_PLAYER2
            Game::finishGame(responseInfo.fromUser)
            return true
         # Cat's game.
         elsif (@turnCounter == 9)
            responseInfo.respond("#{responseInfo.fromUser}, #{otherPlayerName()}: Cat's game.")
            @gameOverStatus = GAME_OVER_TIE
            Game::finishGame(responseInfo.fromUser)
            return true
         else
            @turnCounter += 1
            responseInfo.respond("^#{responseInfo.fromUser} you have moved to (#{row},#{col}).")
         end
      else
         responseInfo.respond("^#{responseInfo.fromUser}: Your move is not properly formatted." +
                              " Try '([row],[col])', where the top left is '(0,0)'.")
         return false
      end
   
      return false
   end

   # Player tokens are 1 and -1, so just to some math on each possible line.
   def gameOver?()
      return ((@board[0][0] + @board[1][1] + @board[2][2]).abs == 3 ||
              (@board[2][0] + @board[1][1] + @board[0][2]).abs == 3 ||
              (@board[0][0] + @board[0][1] + @board[0][2]).abs == 3 ||
              (@board[1][0] + @board[1][1] + @board[1][2]).abs == 3 ||
              (@board[2][0] + @board[2][1] + @board[2][2]).abs == 3 ||
              (@board[0][0] + @board[1][0] + @board[2][0]).abs == 3 ||
              (@board[0][1] + @board[1][1] + @board[2][1]).abs == 3 ||
              (@board[0][2] + @board[1][2] + @board[2][2]).abs == 3)
   end

   def getState
      return "{\"turn\": \"#{currentPlayerName()}\"," +
             " \"player1\": \"#{@player1}\"," +
             " \"player2\": \"#{@player2}\"," +
             " \"board\": #{JSON.dump(@board)}}"
   end

   Game::addSchema('tic-tac-toe', TicTacToe, 'The standard 3x3 Tic-Tac-Toe.', '(row,col)')
end
