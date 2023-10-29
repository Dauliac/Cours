var http = require('http');

// Configure HTTP server respond with Hello World to all requests
var server = http.createServer(function (request, response) {
     response.writeHead(200, {"Content-Type": "text/plain"});
     response.end("Hello World\n");
     });

server.listen(8000, 'localhost');

console.log("Server running at http://localhost:8000/");

