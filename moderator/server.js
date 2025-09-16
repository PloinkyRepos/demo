const http = require('http');
const url = require('url');

const server = http.createServer((req, res) => {
    const handleRequest = (params) => {
        const { from, to, message, command } = params;

        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Access-Control-Allow-Origin', '*'); // Allow requests from any origin
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

        if (req.method === 'OPTIONS') {
            res.writeHead(204);
            res.end();
            return;
        }

        let responsePayload;

        if (command === 'simulator') {
            responsePayload = {
                command: 'redirect',
                to: 'simulator',
                message: message
            };
        } else {
            responsePayload = {
                from: from,
                to: 'all',
                message: message,
                command: command
            };
        }

        res.writeHead(200);
        res.end(JSON.stringify(responsePayload));
    };

    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => {
            body += chunk.toString();
        });
        req.on('end', () => {
            try {
                const params = JSON.parse(body);
                handleRequest(params);
            } catch (e) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Invalid JSON' }));
            }
        });
    } else if (req.method === 'GET') {
        const queryParams = url.parse(req.url, true).query;
        handleRequest(queryParams);
    } else {
        res.writeHead(405, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Method Not Allowed' }));
    }
});

const PORT = 7000;
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
