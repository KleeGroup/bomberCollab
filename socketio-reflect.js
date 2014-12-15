var http    =   require('http');
var fs      =   require('fs');
var url = require("url");

var connect = require('connect');
var serveStatic  = require('serve-static');

var app = connect()
var server = require('http').createServer(app);
var io = require('socket.io')(server);

app.use(serveStatic(__dirname))

// Enables CORS
var enableCORS = function(req, res, next) {
	if(res.header) {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With, *');

        // intercept OPTIONS method
    if ('OPTIONS' == req.method) {
        res.send(200);
    } else {
        next();
    };
  }
};

// enable CORS!
app.use(enableCORS);

// Socket io ecoute maintenant notre application !
var io = require('socket.io');

// Socket io ecoute maintenant notre application !
io = io.listen(server);

io.set('origins', '*:*');
// Quand une personne se connecte au serveur
io.sockets.on('connection', function (socket) {
		console.log(prefixLog(socket)+"Connected" );
     // Quand on recoit un nouveau message
		socket.on('client2Server', function (data) {
	      // On envoie a tout les clients connectes (sauf celui qui a appelle l'evenement) le nouveau message
				socket.broadcast.emit('server2Client', data);
    });
    socket.on('ping', function (data) {
      // On envoie a tout les clients connectes (sauf celui qui a appelle l'evenement) le nouveau message
			socket.broadcast.emit('pong', data);
    }); 
});

// Notre application ecoute sur le port 8080
server.listen(8080);
console.log('Server started. Listen on 8080');
