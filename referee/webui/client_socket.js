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
   data = JSON.parse(messageEvent.data);

   console.log("OnMessage: " + messageEvent.data);

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
   var text = '<ul>'
   for (var i = 0; i < gameList.length; ++i) {
      text += '<li onclick="watchGame(' + gameList[i].id + ');">' +
              gameList[i].gameType + ': ' + gameList[i].player1 +
              ' vs. ' + gameList[i].player2 + '</li>';
   }
   text += '</ul>'

   document.getElementById('main').innerHTML = text;
}

function watchGame(id) {
   var message = {"type": "watchGame", "gameId": id};
   window.socket.send(JSON.stringify(message));
}

function loadGameState(gameType, state) {
   if (gameType == 'TicTacToe') {
      loadTicTacToe(state);
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

window.onload = function() {
   loadSocket();
}
