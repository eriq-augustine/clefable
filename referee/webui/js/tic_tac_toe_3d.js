function loadTicTacToe(state) {
   console.log("TicTac: " + state)

   var piece;
   var html = '<p>X\'s: ' + state.player1 + '</p>' +
          '<p>O\'s: ' + state.player2 + '</p>' +
          '<p>Current Turn: ' + state.turn + '</p>';

   html += "<table style='border:solid'>";
   for (var i = 0; i < 3; i++) {
      html += "<tr>";
      for (var j = 0; j < 3; j++) {
         piece = ' ';
         if (state.board[i][j] == 1) {
            piece = 'X';
         } else if (state.board[i][j] == -1) {
            piece = 'O';
         }

         html += "<td style='border:solid; text-align: center;' height='50px' width='50px'>" + piece + "</td>";
      }
      html += "</tr>";
   }
   html += "</table>";

   document.getElementById('main').innerHTML = html;
}
