function loadBattleship(state) {
   console.log("Battleship: " + JSON.stringify(state))

   player1Board = battleship_makeBoard(state.player1_shots, state.player1);
   player2Board = battleship_makeBoard(state.player2_shots, state.player2);

   var piece;
   var html = '<p>Current Turn: ' + state.turn + '</p>';

   html += '<div id="battleship-board-area">' +
           player1Board +
           player2Board +
           '</div>';

   document.getElementById('main').innerHTML = html;
}

function battleship_makeBoard(shots, player) {
   var piece;
   var board = '<div class="battleship-board">' +
               '<p class="battleship-playername">' + player + '</p>' +
               '<table class="battleship-table">';

   for (var row = 0; row < 10; row++) {
      board += '<tr>';

      for (var col = 0; col < 10; col++) {
         positionKey = "" + row + "-" + col;

         if (shots[positionKey] == undefined) {
            piece = '';
         } else if (shots[positionKey] == 'HIT') {
            piece = '!';
         } else if (shots[positionKey] == 'MISS') {
            piece = 'X';
         } else {
            piece = '';
            console.log("ERROR: Unknown shot type: " + shots[positionKey]);
         }

         board += '<td class="battleship-cell">' + piece + '</td>';
      }
      
      board += '</tr>';
   }

   board += '</table></div>';

   return board
}
