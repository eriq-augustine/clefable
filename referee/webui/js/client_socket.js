window.onload = function() {
   loadSocket();
}

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
   //console.log("OnMessage: " + messageEvent.data);
   
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
   //console.log("Connection to server closed.");
}

function onOpen(messageEvent) {
   //console.log("Connection to server opened: " + JSON.stringify(messageEvent));
   //console.log("Connection to server opened.");
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
   } else if (gameType == 'Battleship') {
     loadBattleship(state);
   } else {
      console.log("Error: Unknown game type: " + gameType);
   }
}
