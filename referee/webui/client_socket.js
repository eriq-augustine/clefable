function loadSocket() {
   //var ws = new WebSocket("ws://localhost:7070/websocket");
   var ws = new WebSocket("ws://50.131.15.127:7070/websocket");
   //var ws = new WebSocket("ws://192.168.1.169:7070/websocket");

   ws.onmessage = onMessage;
   ws.onclose = onClose;
   ws.onopen = onOpen;
   ws.onerror = onError;

   window.socket = ws;
}

function onMessage(messageEvent) {
   console.log("OnMessage: " + messageEvent.data);
   
   data = JSON.parse(messageEvent.data);

   if (data.type == 'gameList') {
      loadGameList(data.games);
   } else if (data.type == 'gameState') {
      loadGameState(data.gameType, data.state);
   } else {
      console.log("Error: Got a message with an unknown type: " + messageEvent.data);
   }
}

function onClose(messageEvent) {
   //console.log("Connection to server closed: " + JSON.stringify(messageEvent));
   console.log("Connection to server closed.");
}

function onOpen(messageEvent) {
   //console.log("Connection to server opened: " + JSON.stringify(messageEvent));
   console.log("Connection to server opened.");
}

function onError(messageEvent) {
   console.log("Error: " + JSON.stringify(messageEvent));
}

function loadGameList(gameList) {
   var activeList = '<ul>';
   var pendingList = '<ul>';
   var element = '';

   for (var i = 0; i < gameList.length; ++i) {
      element = '<li onclick="watchGame(' + gameList[i].id + ');">' +
                gameList[i].gameType + ': ' + gameList[i].player1 +
                ' vs. ' + gameList[i].player2 + '</li>';
      if (gameList[i].pending)
         pendingList += element;
      else
         activeList += element;
   }

   activeList += '</ul>'
   pendingList += '</ul>'

   document.getElementById('main').innerHTML = '<h1>Active Games</h1>' +
                                               activeList +
                                               '<h1>Pending Games</h1>' +
                                               pendingList;
}

function watchGame(id) {
   var message = {"type": "watchGame", "gameId": id};
   window.socket.send(JSON.stringify(message));
}

function loadGameState(gameType, state) {
   if (gameType == 'TicTacToe') {
      loadTicTacToe(state);
   } else if (gameType == 'TicTacToe3D') {
     loadTicTacToe3D(state);
   } else {
      console.log("Error: Unknown game type: " + gameType);
   }
}

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
   document.getElementById('style').setAttribute('href', 'styles/tic_tac_toe_3d.css');
}

window.onload = function() {
   loadSocket();
}
