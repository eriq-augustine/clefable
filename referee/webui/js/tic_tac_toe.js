function loadTicTacToe3D(state) {
   console.log("TicTacToe3D: " + state)

   var piece;
   var html = '<p>X\'s: ' + state.player1 + '</p>' +
          '<p>O\'s: ' + state.player2 + '</p>' +
          '<p>Current Turn: ' + state.turn + '</p>';

   for (var i = 0; i < 3; ++i) {
      html += '<table>';
      for (var j = 0; j < 3; ++j) {
         html += '<tr>';
         for (var k = 0; k < 3; ++k) {
            if (state.board[i][j][k] == 1)
               html += '<td>X</td>';
            else if (state.board[i][j][k] == -1)
               html += '<td>O</td>';
            else
               html += '<td></td>';
         }
         html += "</tr>";
      }
      html += "</table>";
   }

   document.getElementById('main').innerHTML = html;
}
