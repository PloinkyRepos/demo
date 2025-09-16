const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

const forbiddenWords = [
    'fuck', 'bitch', 'shit', 'asshole', 'cunt', 'dick', 'pussy',
    'motherfucker', 'ass', 'cock', 'slut', 'whore', 'damn'
];

let logDir;

function getLogDir() {
    if (logDir) {
        return logDir;
    }

    const localDir = path.join(process.cwd(), '.moderator');

    try {
        fs.mkdirSync(localDir, { recursive: true });
        fs.accessSync(localDir, fs.constants.W_OK);
        logDir = localDir;
        console.log(`Logging to ${logDir}`);
    } catch (e) {
        console.warn(`Could not create or write to ${localDir}, falling back to /tmp`);
        const tmpDir = path.join('/tmp', '.moderator');
        try {
            fs.mkdirSync(tmpDir, { recursive: true });
            logDir = tmpDir;
            console.log(`Logging to ${logDir}`);
        } catch (err) {
            console.error('Could not create log directory in /tmp, logging is disabled.', err);
            logDir = null; // Disable logging
        }
    }
    return logDir;
}


function logCommand(params) {
    const dir = getLogDir();
    if (!dir) {
        return; // Logging is disabled
    }

    const today = new Date();
    const logFileName = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}.log`;
    const logFilePath = path.join(dir, logFileName);
    const logEntry = JSON.stringify(params) + '\n';

    fs.appendFile(logFilePath, logEntry, (err) => {
        if (err) {
            console.error('Failed to write to log file:', err);
        }
    });
}

const server = http.createServer((req, res) => {
    const handleRequest = (params) => {
        logCommand(params);
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

        if (message) {
            const lowerCaseMessage = message.toLowerCase();
            for (const word of forbiddenWords) {
                if (lowerCaseMessage.includes(word)) {
                    const responsePayload = {
                        command: "forbidden",
                        to: from,
                        from: "system",
                        message: "Forbidden message"
                    };
                    res.writeHead(403);
                    res.end(JSON.stringify(responsePayload));
                    return;
                }
            }

            if (lowerCaseMessage.startsWith('simulator')) {
                const simulatorArgs = message.substring('simulator'.length).trim();
                const responsePayload = {
                    command: 'redirect',
                    to: 'simulator',
                    message: simulatorArgs
                };
                res.writeHead(200);
                res.end(JSON.stringify(responsePayload));
                return;
            }
        }

        let responsePayload = {
            from: from,
            to: 'all',
            message: message,
            command: command
        };

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