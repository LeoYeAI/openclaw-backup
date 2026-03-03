#!/usr/bin/env node
/**
 * MyClaw Backup Server — lightweight HTTP server for backup management
 * Part of MyClaw.ai (https://myclaw.ai) open skills ecosystem
 *
 * SECURITY MODEL (enforced in code, not just docs):
 *   - Token is REQUIRED to start (process.exit if missing)
 *   - POST /backup and POST /restore are LOCALHOST-ONLY (127.0.0.1 / ::1)
 *   - Remote clients can only: list, download, upload
 *   - /health is unauthenticated and returns no sensitive info
 *
 * Usage: node server.js --token <secret> [--port 7373] [--backup-dir /tmp/openclaw-backups]
 */

'use strict';
const http = require('http');
const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ── Config ────────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2);
const arg  = (flag, def) => { const i = argv.indexOf(flag); return i !== -1 && argv[i+1] ? argv[i+1] : def; };

const PORT       = parseInt(arg('--port',       process.env.BACKUP_PORT  || '7373'));
const BACKUP_DIR = arg('--backup-dir', process.env.BACKUP_DIR  || '/tmp/openclaw-backups');
const TOKEN      = arg('--token',      process.env.BACKUP_TOKEN || '');
const SKILL_DIR  = path.resolve(__dirname, '..');
const BACKUP_SH  = path.join(SKILL_DIR, 'scripts', 'backup.sh');
const RESTORE_SH = path.join(SKILL_DIR, 'scripts', 'restore.sh');

// ── SECURITY GATE 1: Token required ──────────────────────────────────────────
// This check runs before anything else. No token = no server.
if (!TOKEN) {
  console.error('\n❌  --token is required. This server handles credentials and API keys.');
  console.error('    Example: node server.js --token $(openssl rand -hex 16)\n');
  process.exit(1);
}

// ── SECURITY GATE 2: Localhost-only check (reusable) ─────────────────────────
// Used by /backup and /restore to block remote shell execution.
function isLocalhost(req) {
  const ip = req.socket.remoteAddress || '';
  return ip === '127.0.0.1' || ip === '::1' || ip === '::ffff:127.0.0.1';
}

// ── Ensure backup dir exists ──────────────────────────────────────────────────
fs.mkdirSync(BACKUP_DIR, { recursive: true });

// ── Helpers ───────────────────────────────────────────────────────────────────
const SECURE_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Cache-Control': 'no-store'
};

function json(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json', ...SECURE_HEADERS });
  res.end(JSON.stringify(data, null, 2));
}

function fmt(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes/1024).toFixed(1) + ' KB';
  return (bytes/1048576).toFixed(1) + ' MB';
}

function listBackups() {
  return fs.readdirSync(BACKUP_DIR)
    .filter(f => f.startsWith('openclaw-backup_') && f.endsWith('.tar.gz'))
    .map(f => {
      const stat = fs.statSync(path.join(BACKUP_DIR, f));
      return { filename: f, size: stat.size, sizeHuman: fmt(stat.size), createdAt: stat.mtime.toISOString(),
               downloadUrl: `/download/${f}?token=${TOKEN}` };
    })
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

function checkAuth(req) {
  const q = new URL('http://x' + req.url).searchParams.get('token');
  const h = (req.headers['authorization'] || '').replace('Bearer ', '').trim();
  return q === TOKEN || h === TOKEN;
}

// ── Multipart parser (no deps) ────────────────────────────────────────────────
function parseMultipart(req, cb) {
  const ct = req.headers['content-type'] || '';
  const bm = ct.match(/boundary=(.+)$/);
  if (!bm) return cb(new Error('No boundary'));
  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const headerEnd = body.indexOf('\r\n\r\n');
    const headerStr = body.slice(0, headerEnd).toString();
    const fnm = headerStr.match(/filename="([^"]+)"/);
    if (!fnm) return cb(new Error('No filename'));
    const filename = path.basename(fnm[1]);
    const start = headerEnd + 4;
    const endBoundary = Buffer.from('\r\n--' + bm[1]);
    const end = body.indexOf(endBoundary, start);
    cb(null, { filename, data: end > 0 ? body.slice(start, end) : body.slice(start) });
  });
  req.on('error', cb);
}

// ── Web UI ────────────────────────────────────────────────────────────────────
function serveUI(req, res) {
  const uiPath = path.join(SKILL_DIR, 'scripts', 'ui.html');
  let html = fs.existsSync(uiPath) ? fs.readFileSync(uiPath, 'utf8') : '<h1>UI not found</h1>';
  const backups = listBackups();
  const rows = backups.map(b =>
    `<tr><td><span class="tag">tar.gz</span> ${b.filename}</td><td>${b.sizeHuman}</td>` +
    `<td>${new Date(b.createdAt).toLocaleString()}</td>` +
    `<td class="actions"><a class="btn btn-gray" href="${b.downloadUrl}" download>⬇ Download</a>` +
    `<button class="btn btn-success restore-btn" data-file="${b.filename}">👁 Dry Run</button>` +
    `<button class="btn btn-danger restore-btn" data-file="${b.filename}" data-confirm="1">♻️ Restore</button></td></tr>`
  ).join('');
  html = html
    .replace('{{TOKEN}}', TOKEN)
    .replace('{{BACKUP_COUNT}}', String(backups.length))
    .replace('{{BACKUP_ROWS}}', backups.length ? rows : '<tr><td colspan="4" class="empty">No backups yet.</td></tr>');
  res.writeHead(200, { 'Content-Type': 'text/html', ...SECURE_HEADERS });
  res.end(html);
}

// ── Router ────────────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  const urlPath = new URL('http://x' + req.url).pathname;

  // /health — no auth, minimal info only
  if (req.method === 'GET' && urlPath === '/health') {
    return json(res, 200, { status: 'ok', service: 'myclaw-backup' });
  }

  // All other routes require auth
  if (!checkAuth(req)) {
    return json(res, 401, { error: 'Unauthorized. Pass ?token=xxx or Authorization: Bearer xxx' });
  }

  // GET / — Web UI
  if (req.method === 'GET' && urlPath === '/') return serveUI(req, res);

  // GET /backups — list
  if (req.method === 'GET' && urlPath === '/backups') {
    return json(res, 200, { backups: listBackups() });
  }

  // POST /backup — LOCALHOST ONLY (shell execution)
  if (req.method === 'POST' && urlPath === '/backup') {
    if (!isLocalhost(req)) {
      return json(res, 403, { error: 'POST /backup is localhost-only.', hint: 'Run backup.sh directly on this machine.' });
    }
    try {
      execSync(`chmod +x "${BACKUP_SH}"`);
      const out = execSync(`bash "${BACKUP_SH}" "${BACKUP_DIR}"`, { encoding: 'utf8', timeout: 120000 });
      const latest = listBackups()[0];
      return json(res, 200, { message: 'Backup created', filename: latest?.filename, size: latest?.sizeHuman,
                               downloadUrl: latest?.downloadUrl, output: out.replace(/\x1b\[[0-9;]*m/g, '') });
    } catch (e) { return json(res, 500, { error: e.message }); }
  }

  // GET /download/:filename
  if (req.method === 'GET' && urlPath.startsWith('/download/')) {
    const filename = path.basename(decodeURIComponent(urlPath.slice('/download/'.length)));
    const filePath = path.join(BACKUP_DIR, filename);
    if (!fs.existsSync(filePath) || !filename.endsWith('.tar.gz')) {
      return json(res, 404, { error: 'File not found' });
    }
    const stat = fs.statSync(filePath);
    res.writeHead(200, { 'Content-Type': 'application/gzip',
      'Content-Disposition': `attachment; filename="${filename}"`, 'Content-Length': stat.size });
    fs.createReadStream(filePath).pipe(res);
    return;
  }

  // POST /upload — allowed from remote (upload only, no execution)
  if (req.method === 'POST' && urlPath === '/upload') {
    return parseMultipart(req, (err, file) => {
      if (err) return json(res, 400, { error: err.message });
      if (!file.filename.endsWith('.tar.gz')) return json(res, 400, { error: 'Only .tar.gz files accepted' });
      const dest = path.join(BACKUP_DIR, path.basename(file.filename));
      fs.writeFileSync(dest, file.data);
      fs.chmodSync(dest, 0o600);
      return json(res, 200, { message: 'Upload successful', filename: file.filename, size: fmt(file.data.length) });
    });
  }

  // POST /restore/:filename — LOCALHOST ONLY (shell execution)
  if (req.method === 'POST' && urlPath.startsWith('/restore/')) {
    if (!isLocalhost(req)) {
      return json(res, 403, {
        error: 'POST /restore is localhost-only.',
        hint: 'Download the backup file and run: bash restore.sh <archive> --dry-run'
      });
    }
    const filename = path.basename(decodeURIComponent(urlPath.slice('/restore/'.length)));
    const filePath = path.join(BACKUP_DIR, filename);
    const params   = new URL('http://x' + req.url).searchParams;
    const isDryRun = params.get('dry_run') === '1';
    const confirmed = params.get('confirm') === '1';
    if (!fs.existsSync(filePath)) return json(res, 404, { error: 'File not found: ' + filename });
    if (!isDryRun && !confirmed) {
      return json(res, 400, { error: 'Add ?confirm=1 to apply restore. Run ?dry_run=1 first to preview.' });
    }
    try {
      execSync(`chmod +x "${RESTORE_SH}"`);
      const cmd = isDryRun ? `bash "${RESTORE_SH}" "${filePath}" --dry-run`
                           : `echo 'yes' | bash "${RESTORE_SH}" "${filePath}"`;
      const out = execSync(cmd, { encoding: 'utf8', timeout: 180000 });
      return json(res, 200, { message: isDryRun ? 'Dry run complete' : 'Restore complete',
                               dryRun: isDryRun, output: out.replace(/\x1b\[[0-9;]*m/g, '') });
    } catch (e) { return json(res, 500, { error: e.message, output: (e.stdout||'').replace(/\x1b\[[0-9;]*m/g, '') }); }
  }

  json(res, 404, { error: 'Not found' });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🦞 MyClaw Backup Server`);
  console.log(`   Token protected | Localhost-only for /backup and /restore`);
  console.log(`   http://localhost:${PORT}/?token=${TOKEN}`);
  console.log(`   ⚠️  Do not expose this port to the internet without TLS.\n`);
});
server.on('error', err => { console.error('Server error:', err.message); process.exit(1); });
