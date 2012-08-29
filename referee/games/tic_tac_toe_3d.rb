class TicTacToe3D < Game
  EMPTY = 0
  PLAYER1 = 1
  PLAYER2 = -1

  def initialize(startingPlayer, pendingPlayer)
    super(startingPlayer, pendingPlayer)

    @board = [[[EMPTY, EMPTY, EMPTY],
               [EMPTY, EMPTY, EMPTY],
               [EMPTY, EMPTY, EMPTY]],

              [[EMPTY, EMPTY, EMPTY],
               [EMPTY, EMPTY, EMPTY],
               [EMPTY, EMPTY, EMPTY]],

              [[EMPTY, EMPTY, EMPTY],
               [EMPTY, EMPTY, EMPTY],
               [EMPTY, EMPTY, EMPTY]]]

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

    if (match = args.strip.match(/\(?\s*(\d)\s*,?\s*(\d)\s*,?\s*(\d)\s*\)?/))
      level = match[1].to_i
      row = match[2].to_i
      col = match[3].to_i

      if (level < 0 || level > 2 || row < 0 || row > 2 || col < 0 || col > 2)
        responseInfo.repspond("(#{level},#{row},#{col}) is not a valid location." +
                              " The valid range is (0,0,0) to (2,2,2).")
        return false
      end

      if (@board[level][row][col] != EMPTY)
        responseInfo.respond("(#{level},#{row},#{col}) is already taken. Choose another spot.")
        return false
      end

      @board[level][row][col] = currentPlayerToken()

      if (gameOver?())
        responseInfo.respond("Congrats #{responseInfo.fromUser}! You Won!")
        @gameOverStatus = (@turnCounter % 2 == 1) ? GAME_OVER_PLAYER1 : GAME_OVER_PLAYER2
        Game::finishGame(responseInfo.fromUser)
        return true
      # Cat's game.
      elsif (@turnCounter == 27)
        responseInfo.respond("#{responseInfo.fromUser}, #{otherPlayerName()}: Cat's game.")
        @gameOverStatus = GAME_OVER_TIE
        Game::finishGame(responseInfo.fromUser)
        return true
      else
        @turnCounter += 1
        responseInfo.respond("^#{responseInfo.fromUser} you have moved to (#{level},#{row},#{col}).")
      end
    else
      responseInfo.respond("^#{responseInfo.fromUser}: Your move is not properly formatted." +
                           " Try '([level],[row],[col])', where the top left is '(0,0,0)'" +
                           " and the top right is '(0,0,2)'")
      return false
    end
   
    return false
  end

  # Player tokens are 1 and -1, so just to some math on each possible line.
  def gameOver?()
    for i in 0..2
      for j in 0..2
        if (# Single-level row or column wins.
            (@board[i][j][0] + @board[i][j][1] + @board[i][j][2]).abs == 3 ||
            (@board[i][0][j] + @board[i][1][j] + @board[i][2][j]).abs == 3 ||

            # Straight down.
            (@board[0][i][j] + @board[1][i][j] + @board[2][i][j]).abs == 3)
          return true
        end
      end

      if (# Single-level diagonal wins.
          (@board[i][0][0] + @board[i][1][1] + @board[i][2][2]).abs == 3 ||
          (@board[i][2][0] + @board[i][1][1] + @board[i][0][2]).abs == 3 ||

          # Multi-level, single row wins.
          (@board[0][i][0] + @board[1][i][1] + @board[2][i][2]).abs == 3 ||
          (@board[0][i][2] + @board[1][i][1] + @board[2][i][0]).abs == 3 ||

          # Multi-level, single column wins.
          (@board[0][0][i] + @board[1][1][i] + @board[2][2][i]).abs == 3 ||
          (@board[0][2][i] + @board[1][1][i] + @board[2][0][i]).abs == 3)
        return true
      end
    end

    # Multi-level diagonal wins.
    return ((@board[0][0][0] + @board[1][1][1] + @board[2][2][2]).abs == 3 ||
            (@board[0][0][2] + @board[1][1][1] + @board[2][2][0]).abs == 3 ||
            (@board[0][2][2] + @board[1][1][1] + @board[2][0][0]).abs == 3 ||
            (@board[0][2][0] + @board[1][1][1] + @board[2][0][2]).abs == 3)
  end

  def getState
    return "{\"turn\": \"#{currentPlayerName()}\"," +
           " \"player1\": \"#{@player1}\"," +
           " \"player2\": \"#{@player2}\"," +
           " \"board\": #{JSON.dump(@board)}}"
  end

  Game::addSchema('tic-tac-toe-3d', TicTacToe3D, 'Tic-Tac-Toe 3D.', '(level,row,col)')
end
