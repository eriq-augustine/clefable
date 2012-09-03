class Battleship < Game
   BOARD_SIZE = 10

   # Using strings and not ints makes it faster
   #  to convert state for the UI.
   SHOT_TYPE_MISS = 'MISS'
   SHOT_TYPE_HIT = 'HIT'

   # All the different types of boats!
   # TODO(eriq): These are strings now instead of ints beccause
   #  it makes it easier to parse the JSON struct.
   #  When the position placing is no longer a json struct, make these ints.
   BOAT_TYPE_CARRIER = 'C'
   BOAT_TYPE_BATTLESHIP = 'B'
   BOAT_TYPE_SUB = 'S'
   BOAT_TYPE_DESTROYER = 'D'
   BOAT_TYPE_PT = 'PT'

   # Some hashes to access boat meta info.
   BOAT_NAME = {BOAT_TYPE_CARRIER => "Aircraft Carrier",
                BOAT_TYPE_BATTLESHIP => "Battleship",
                BOAT_TYPE_SUB => "Submarine",
                BOAT_TYPE_DESTROYER => "Destroyer",
                BOAT_TYPE_PT => "Patrol Boat"}
   # Max hp for each boat.
   BOAT_HP = {BOAT_TYPE_CARRIER => 5,
              BOAT_TYPE_BATTLESHIP => 4,
              BOAT_TYPE_SUB => 3, 
              BOAT_TYPE_DESTROYER => 2,
              BOAT_TYPE_PT => 2}


   def initialize(startingPlayer, pendingPlayer)
      super(startingPlayer, pendingPlayer)

      # The players' boats.
      # { BOAT_TYPE => health }
      @player1Boats = nil
      @player2Boats = nil

      # The players' boats' locations.
      # { #{row-col} => BOAT_TYPE }
      @player1BoatLocations = nil
      @player2BoatLocations = nil

      # The shots that each player has performed.
      # Remember: One player's board is seperate from another.
      # { #{row-col} => SHOT_TYPE }
      @player1Shots = Hash.new()
      @player2Shots = Hash.new()

      @turnCounter = 1
   end

   # TODO(eriq): There must be a better way for all these player choosers.
   #  As long as the games are always turn-based, we can move these to super-class.
   def player1Turn?
      return @turnCounter % 2 == 1
   end

   def isPlayer1?(playerName)
      return @player1 == playerName
   end

   def otherPlayerName
      if (player1Turn?())
         return @player2
      else
         return @player1
      end
   end

   def currentPlayerName
      if (player1Turn?())
         return @player1
      else
         return @player2
      end
   end

   # TODO(eriq): Split this into two methods once there is a decision about accessing a
   #  specific player's data.
   def currentPlayerInfo
      if (player1Turn?())
         return {:boats => @player1Boats, :shots => @player1Shots,
                 :boatLocations => @player1BoatLocations}
      else
         return {:boats => @player2Boats, :shots => @player2Shots,
                 :boatLocations => @player2BoatLocations}
      end
   end
   
   def otherPlayerInfo
      if (player1Turn?())
         return {:boats => @player2Boats, :shots => @player2Shots,
                 :boatLocations => @player2BoatLocations}
      else
         return {:boats => @player1Boats, :shots => @player1Shots,
                 :boatLocations => @player1BoatLocations}
      end
   end


   def takeTurn(responseInfo, args)
      if (!@player1Boats || !@player2Boats)
         handlePlaceBoats(responseInfo, args)
         return false
      else
         return handleShoot(responseInfo, args)
      end
   end

   # TODO: This is REALLLLLLY bad right now.
   # Make it easier for the user, and document it well somewhere.
   def handlePlaceBoats(responseInfo, args)
      # No double place
      if ((isPlayer1?(responseInfo.fromUser) && @player1Boats) ||
          (!isPlayer1?(responseInfo.fromUser) && @player2Boats))
         opponentName = isPlayer1?(responseInfo.fromUser) ? @player2 : @player1
         responseInfo.respond("^#{responseInfo.fromUser}: You have already placed your boats, but ^#{opponentName} has not. Wait for them.")
         return
      end

      # TODO(eriq): Make this nicer for the user.
      # Right now, ship positions are expected in JSON.
      parsedLocations = nil

      begin
         parsedLocations = JSON.parse(args)
      rescue Exception => detail
         responseInfo.respond("^#{responseInfo.fromUser}: There was an error parsing your locations.")
         #TEST
         puts "Parse Error: #{detail.message()}"
         return
      end

      boats = Hash.new()
      locations = Hash.new()

      if (errorMessage = verifyLocationSchema(parsedLocations, boats, locations))
         responseInfo.respond("^#{responseInfo.fromUser}: There is an error with your position schema: #{errorMessage}.")
         return
      end

      responseInfo.respond("^#{responseInfo.fromUser}: Your boat locations have been accepted.")

      if (isPlayer1?(responseInfo.fromUser))
         @player1Boats = boats
         @player1BoatLocations = locations
      else
         @player2Boats = boats
         @player2BoatLocations = locations
      end
   end

   # Ex of good schema:
   #  { "C":  {"start": {"row": 0, "col": 0}, "end": {"row": 0, "col": 4}},
   #    "B":  {"start": {"row": 1, "col": 0}, "end": {"row": 1, "col": 3}},
   #    "S":  {"start": {"row": 2, "col": 0}, "end": {"row": 2, "col": 2}},
   #    "D":  {"start": {"row": 3, "col": 0}, "end": {"row": 3, "col": 1}},
   #    "PT": {"start": {"row": 4, "col": 0}, "end": {"row": 4, "col": 1}} }
   # On success nil it returned and |boats| and |locations| is filled.
   # On failure, an error string is returned.
   def verifyLocationSchema(parsedLocations, boats, locations)
      BOAT_NAME.each_key{|boatName|
         if (!parsedLocations.has_key?(boatName))
            return "Missing boat type: #{BOAT_NAME[boatName]}"
         end

         positions = parsedLocations[boatName]

         ['start', 'end'].each{|startEndKey|
            if (!positions.has_key?(startEndKey))
               return "'#{boatName}' is missing the '#{startEndKey}' key."
            end

            ['row', 'col'].each{|rowColKey|
               if (!positions[startEndKey].has_key?(rowColKey))
                  return "'#{boatName}'['#{startEndKey}'] is missing the '#{rowColKey}' key."
               end
            }
         }

         startRow = positions['start']['row'].to_i
         startCol = positions['start']['col'].to_i
         endRow = positions['end']['row'].to_i
         endCol = positions['end']['col'].to_i

         if (startRow < 0 || startRow >= BOARD_SIZE ||
             startCol < 0 || startCol >= BOARD_SIZE ||
             endRow < 0 || endRow >= BOARD_SIZE ||
             endCol < 0 || endCol >= BOARD_SIZE)
            return "'#{boatName}' has a bad position." +
                   " The valid range is (0,0) to (#{BOARD_SIZE - 1},#{BOARD_SIZE - 1})."
         end
         
         # Must be straight.
         if (startRow != endRow && startCol != endCol)
            return "'#{boatName}' must be straight (vertical or horizontal)."
         end

         if ((((startRow - endRow) + (startCol - endCol)).abs() + 1) != BOAT_HP[boatName])
            #TEST
            puts "Got size: #{((startRow - endRow) + (startCol - endCol)).abs()}"

            return "'#{boatName}' is the wrong length. It must be #{BOAT_HP[boatName]}."
         end

         boats[boatName] = BOAT_HP[boatName]
         for row in startRow..endRow
            for col in startCol..endCol
               locations["#{row}-#{col}"] = boatName
            end
         end
      }

      return nil
   end

   def handleShoot(responseInfo, args)
      if (responseInfo.fromUser != currentPlayerName())
         responseInfo.respond("^#{responseInfo.fromUser}: It is not your turn.")
         return false
      end

      match = nil
      if (!(match = args.strip.match(/\(?\s*(\d)\s*,?\s*(\d)\s*\)?/)))
         responseInfo.respond("^#{responseInfo.fromUser}: Your move is invalid. Try MOVE-SYNTAX battleship")
         return false
      end

      row = match[1].to_i
      col = match[2].to_i

      if (row < 0 || row >= BOARD_SIZE || col < 0 || col >= BOARD_SIZE)
         responseInfo.respond("(#{row},#{col}) is not a valid location." +
                              " The valid range is (0,0) to (#{BOARD_SIZE - 1}, #{BOARD_SIZE - 1}).")
         return false
      end

      shotKey = "#{row}-#{col}"
      currentShots = currentPlayerInfo()[:shots]
      otherBoats = otherPlayerInfo()[:boats]
      otherBoatLocations = otherPlayerInfo()[:boatLocations]

      if (currentShots.has_key?(shotKey))
         responseInfo.respond("^#{responseInfo.fromUser}, you already shot at (#{row},#{col})." + 
                              " Choose another spot.")
         return false
      end

      # Note: Don't return out from there.
      #  There is much book keeping to do.

      shotType = nil
      if (otherBoatLocations.has_key?(shotKey))
         # hit
         shotType = SHOT_TYPE_HIT
         hitType = otherBoatLocations[shotKey]
         
         # sink!
         if ((otherBoats[hitType] -= 1) == 0)
            responseInfo.respond("^#{responseInfo.fromUser}, you have sunk ^#{otherPlayerName}'s #{BOAT_NAME[hitType]}!")
         else
            responseInfo.respond("^#{responseInfo.fromUser}: HIT!")
         end
      else
         # miss
         shotType = SHOT_TYPE_MISS
         responseInfo.respond("^#{responseInfo.fromUser}: Miss.")
      end

      currentShots[shotKey] = shotType

      if (gameOver?())
         responseInfo.respond("#{responseInfo.fromUser} CONGRATULATIONS, you have bested #{otherPlayerName} in naval combat!")
         @gameOverStatus = (@turnCounter % 2 == 1) ? GAME_OVER_PLAYER1 : GAME_OVER_PLAYER2
         Game::finishGame(responseInfo.fromUser)
         return true
      end

      @turnCounter += 1
      return false
   end

   def gameOver?()
      player1Health = 0
      player2Health = 0

      BOAT_NAME.each_key{|boat|
         player1Health += @player1Boats[boat]
         player2Health += @player2Boats[boat]
      }

      return player1Health == 0 || player2Health == 0
   end

   def getState
      return "{\"turn\": \"#{currentPlayerName()}\"," +
             " \"player1\": \"#{@player1}\"," +
             " \"player2\": \"#{@player2}\"," +
             " \"player1_shots\": #{JSON.dump(@player1Shots)}," + 
             " \"player2_shots\": #{JSON.dump(@player2Shots)}}"
   end

   Game::addSchema('battleship', Battleship, 'Standard 10 x 10 Battleship!', '(row,col)')
end
