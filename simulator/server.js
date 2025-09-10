#!/usr/bin/env node
const http = require('http');
const url = require('url');
const querystring = require('querystring');
const { spawn } = require('child_process');

const PORT = parseInt(process.env.PORT || '7000', 10);

function runSimulator(payload, cb) {
  try {
    const b64 = Buffer.from(JSON.stringify(payload || {}), 'utf8').toString('base64');
    const child = spawn('node', ['/code/simulator.js', b64], { stdio: ['ignore', 'pipe', 'pipe'] });
    let out = Buffer.alloc(0);
    let err = Buffer.alloc(0);
    child.stdout.on('data', d => { out = Buffer.concat([out, d]); });
    child.stderr.on('data', d => { err = Buffer.concat([err, d]); });
    child.on('close', code => {
      if (code === 0) cb(null, out.toString('utf8'));
      else cb(new Error(`simulator exited code ${code}: ${err.toString('utf8')}`));
    });
  } catch (e) {
    cb(e);
  }
}

const server = http.createServer((req, res) => {
  const u = url.parse(req.url);
  if (req.method === 'GET' && u.pathname === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ ok: true }));
  }
  if (u.pathname === '/api') {
    const done = (status, bodyObj) => {
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(bodyObj));
    };
    if (req.method === 'GET') {
      const params = querystring.parse(u.query || '');
      return runSimulator(params, (err, html) => {
        if (err) return done(500, { ok: false, error: String(err) });
        return done(200, { ok: true, html });
      });
    }
    if (req.method === 'POST') {
      const chunks = [];
      req.on('data', c => chunks.push(c));
      req.on('end', () => {
        let payload = {};
        try { payload = JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}'); } catch (_) {}
        return runSimulator(payload, (err, html) => {
          if (err) return done(500, { ok: false, error: String(err) });
          return done(200, { ok: true, html });
        });
      });
      return;
    }
    res.writeHead(405, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ ok: false, error: 'method not allowed' }));
  }
  res.statusCode = 404; res.end('not found');
});

server.listen(PORT, () => {
  console.log(`[simulator] listening on ${PORT}`);
});

