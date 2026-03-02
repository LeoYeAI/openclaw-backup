#!/usr/bin/env node
/**
 * openclaw-backup-server: Lightweight HTTP server for backup download/upload/restore
 *
 * Usage: node server.js [--port 7373] [--backup-dir /tmp/openclaw-backups] [--token mytoken]
 *
 * Endpoints:
 *   GET  /                     → Web UI (browser-friendly)
 *   GET  /backups              → List available backups (JSON)
 *   POST /backup               → Trigger a new backup, returns download link
 *   GET  /download/:filename   → Download a backup file
 *   POST /upload               → Upload a backup file (multipart/form-data, field: "backup")
 *   POST /restore/:filename    → Restore from an uploaded backup (dry-run=1 for preview)
 *   GET  /health               → Health check
 *
 * Auth: pass ?token=xxx or header Authorization: Bearer xxx
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');
const os = require('os');

// ── Config ───────────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const getArg = (flag, def) => {
  const i = args.indexOf(flag);
  return i !== -1 && args[i + 1] ? args[i + 1] : def;
};

const PORT = parseInt(getArg('--port', process.env.BACKUP_PORT || '7373'));
const BACKUP_DIR = getArg('--backup-dir', process.env.BACKUP_DIR || '/tmp/openclaw-backups');
const TOKEN = getArg('--token', process.env.BACKUP_TOKEN || '');
const SKILL_DIR = path.resolve(__dirname, '..');
const BACKUP_SCRIPT = path.join(SKILL_DIR, 'scripts', 'backup.sh');
const RESTORE_SCRIPT = path.join(SKILL_DIR, 'scripts', 'restore.sh');

// ── Token enforcement ─────────────────────────────────────────────────────────
// Token is required — this server handles highly sensitive data (credentials, API keys).
// Refusing to start without a token prevents accidental open exposure.
if (!TOKEN) {
  console.error('');
  console.error('❌ ERROR: --token is required.');
  console.error('');
  console.error('   This server handles sensitive data (bot tokens, API keys, credentials).');
  console.error('   You must set a token to protect access.');
  console.error('');
  console.error('   Example:');
  console.error('     node server.js --token $(openssl rand -hex 16)');
  console.error('');
  process.exit(1);
}

// Ensure backup dir exists
fs.mkdirSync(BACKUP_DIR, { recursive: true });

// ── Auth ─────────────────────────────────────────────────────────────────────
function checkAuth(req) {
  // Token is always required (enforced at startup above)
  const fromQuery = new URL('http://x' + req.url).searchParams.get('token');
  const fromHeader = (req.headers['authorization'] || '').replace('Bearer ', '').trim();
  return fromQuery === TOKEN || fromHeader === TOKEN;
}

// ── Helpers ──────────────────────────────────────────────────────────────────
function listBackups() {
  try {
    return fs.readdirSync(BACKUP_DIR)
      .filter(f => f.startsWith('openclaw-backup_') && f.endsWith('.tar.gz'))
      .map(f => {
        const stat = fs.statSync(path.join(BACKUP_DIR, f));
        return {
          filename: f,
          size: stat.size,
          sizeHuman: formatBytes(stat.size),
          createdAt: stat.mtime.toISOString(),
          downloadUrl: `/download/${f}${TOKEN ? '?token=' + TOKEN : ''}`
        };
      })
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  } catch { return []; }
}

function formatBytes(bytes) {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / 1024 / 1024).toFixed(1) + ' MB';
}

// ── Security headers helper ───────────────────────────────────────────────────
function secureHeaders() {
  return {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Cache-Control': 'no-store'
  };
}

function json(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json', ...secureHeaders() });
  res.end(JSON.stringify(data, null, 2));
}

function parseUrlPath(url) {
  return new URL('http://x' + url).pathname;
}

// ── Multipart parser (no deps) ────────────────────────────────────────────────
function parseMultipart(req, callback) {
  const contentType = req.headers['content-type'] || '';
  const boundaryMatch = contentType.match(/boundary=(.+)$/);
  if (!boundaryMatch) return callback(new Error('No boundary in multipart'));
  const boundary = Buffer.from('--' + boundaryMatch[1]);

  const chunks = [];
  req.on('data', chunk => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    // Find filename
    const headerEnd = body.indexOf('\r\n\r\n');
    const headerStr = body.slice(0, headerEnd).toString();
    const fnMatch = headerStr.match(/filename="([^"]+)"/);
    if (!fnMatch) return callback(new Error('No filename in upload'));
    const filename = path.basename(fnMatch[1]);

    // Extract file content between boundary markers
    const start = headerEnd + 4;
    const endBoundary = Buffer.from('\r\n--' + boundaryMatch[1]);
    const end = body.indexOf(endBoundary, start);
    const fileData = end > 0 ? body.slice(start, end) : body.slice(start);

    callback(null, { filename, data: fileData });
  });
  req.on('error', callback);
}

// ── Web UI ────────────────────────────────────────────────────────────────────
function serveUI(req, res) {
  const backups = listBackups();
  const tokenParam = TOKEN ? `?token=${TOKEN}` : '';
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>🦞 OpenClaw Backup</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0f1117; color: #e2e8f0; min-height: 100vh; padding: 2rem; }
  h1 { font-size: 1.6rem; margin-bottom: 0.3rem; }
  .sub { color: #64748b; font-size: 0.85rem; margin-bottom: 2rem; }
  .card { background: #1e2130; border: 1px solid #2d3148; border-radius: 12px; padding: 1.5rem; margin-bottom: 1.5rem; }
  h2 { font-size: 1rem; color: #94a3b8; margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em; }
  .btn { display: inline-block; padding: 0.5rem 1.2rem; border-radius: 8px; border: none; cursor: pointer; font-size: 0.9rem; font-weight: 500; transition: opacity 0.15s; text-decoration: none; }
  .btn:hover { opacity: 0.85; }
  .btn-primary { background: #6366f1; color: white; }
  .btn-success { background: #22c55e; color: white; }
  .btn-danger  { background: #ef4444; color: white; }
  .btn-gray    { background: #334155; color: #e2e8f0; }
  table { width: 100%; border-collapse: collapse; font-size: 0.88rem; }
  th { text-align: left; padding: 0.5rem 0.75rem; color: #64748b; border-bottom: 1px solid #2d3148; }
  td { padding: 0.6rem 0.75rem; border-bottom: 1px solid #1a1f2e; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #252a3d; }
  .tag { display: inline-block; padding: 0.15rem 0.5rem; border-radius: 4px; font-size: 0.75rem; background: #1e3a5f; color: #60a5fa; }
  .empty { color: #475569; text-align: center; padding: 2rem; }
  .upload-zone { border: 2px dashed #334155; border-radius: 8px; padding: 2rem; text-align: center; cursor: pointer; transition: border-color 0.2s; }
  .upload-zone:hover, .upload-zone.drag { border-color: #6366f1; }
  .upload-zone input { display: none; }
  .upload-zone p { color: #64748b; margin-top: 0.5rem; font-size: 0.85rem; }
  .status { padding: 0.75rem 1rem; border-radius: 8px; margin-top: 1rem; font-size: 0.88rem; display: none; }
  .status.ok  { background: #14532d; color: #86efac; display: block; }
  .status.err { background: #7f1d1d; color: #fca5a5; display: block; }
  .actions { display: flex; gap: 0.5rem; flex-wrap: wrap; }
</style>
</head>
<body>
<h1>🦞 OpenClaw Backup</h1>
<p class="sub">Backup manager — download, upload and restore your OpenClaw instance</p>

<!-- Create Backup -->
<div class="card">
  <h2>Create Backup</h2>
  <div class="actions">
    <button class="btn btn-primary" onclick="createBackup()">⚡ Create Backup Now</button>
  </div>
  <div id="create-status" class="status"></div>
</div>

<!-- Upload Backup -->
<div class="card">
  <h2>Upload Backup</h2>
  <div class="upload-zone" id="drop-zone" onclick="document.getElementById('file-input').click()"
    ondragover="event.preventDefault();this.classList.add('drag')"
    ondragleave="this.classList.remove('drag')"
    ondrop="handleDrop(event)">
    <div style="font-size:2rem">📦</div>
    <strong>Click to select</strong> or drag & drop
    <p>openclaw-backup_*.tar.gz</p>
    <input type="file" id="file-input" accept=".tar.gz,.gz" onchange="uploadFile(this.files[0])">
  </div>
  <div id="upload-status" class="status"></div>
</div>

<!-- Backup List -->
<div class="card">
  <h2>Available Backups (${backups.length})</h2>
  ${backups.length === 0 ? '<p class="empty">No backups yet. Create one above.</p>' : `
  <table>
    <tr><th>Filename</th><th>Size</th><th>Created</th><th>Actions</th></tr>
    ${backups.map(b => `
    <tr>
      <td><span class="tag">tar.gz</span> ${b.filename}</td>
      <td>${b.sizeHuman}</td>
      <td>${new Date(b.createdAt).toLocaleString()}</td>
      <td class="actions">
        <a class="btn btn-gray" href="${b.downloadUrl}" download>⬇ Download</a>
        <button class="btn btn-success" onclick="restore('${b.filename}', true)">👁 Dry Run</button>
        <button class="btn btn-danger" onclick="restore('${b.filename}', false)">♻️ Restore</button>
      </td>
    </tr>`).join('')}
  </table>`}
</div>

<script>
const token = '${TOKEN}';
const headers = token ? { 'Authorization': 'Bearer ' + token } : {};

async function createBackup() {
  const el = document.getElementById('create-status');
  el.className = 'status ok'; el.textContent = '⏳ Creating backup...'; el.style.display = 'block';
  try {
    const r = await fetch('/backup', { method: 'POST', headers });
    const d = await r.json();
    if (r.ok) {
      el.textContent = '✅ ' + d.message + ' — ' + d.filename;
      setTimeout(() => location.reload(), 1500);
    } else { el.className = 'status err'; el.textContent = '❌ ' + (d.error || 'Failed'); }
  } catch(e) { el.className = 'status err'; el.textContent = '❌ ' + e.message; }
}

async function uploadFile(file) {
  if (!file) return;
  const el = document.getElementById('upload-status');
  el.className = 'status ok'; el.textContent = '⏳ Uploading ' + file.name + '...'; el.style.display = 'block';
  const fd = new FormData(); fd.append('backup', file);
  try {
    const r = await fetch('/upload', { method: 'POST', headers, body: fd });
    const d = await r.json();
    if (r.ok) { el.textContent = '✅ Uploaded: ' + d.filename; setTimeout(() => location.reload(), 1000); }
    else { el.className = 'status err'; el.textContent = '❌ ' + (d.error || 'Upload failed'); }
  } catch(e) { el.className = 'status err'; el.textContent = '❌ ' + e.message; }
}

function handleDrop(e) {
  e.preventDefault();
  document.getElementById('drop-zone').classList.remove('drag');
  const file = e.dataTransfer.files[0];
  if (file) uploadFile(file);
}

async function restore(filename, dryRun) {
  const label = dryRun ? 'Dry run' : 'RESTORE';
  if (!dryRun) {
    const msg = '⚠️ RESTORE will OVERWRITE your current OpenClaw data with:\\n\\n' + filename + '\\n\\nHave you reviewed the dry-run output first?\\n\\nType YES to confirm:';
    const input = prompt(msg);
    if (input !== 'YES') { alert('Aborted. Run dry-run first to review what will change.'); return; }
  }
  const el = document.getElementById('create-status');
  el.className = 'status ok'; el.textContent = '⏳ ' + label + ' in progress...'; el.style.display = 'block';
  try {
    const params = new URLSearchParams();
    if (token) params.set('token', token);
    if (dryRun) params.set('dry_run', '1');
    else params.set('confirm', '1');
    const url = '/restore/' + encodeURIComponent(filename) + '?' + params.toString();
    const r = await fetch(url, { method: 'POST', headers });
    const d = await r.json();
    if (r.ok) {
      el.textContent = '✅ ' + label + ' complete.';
      if (d.output) {
        const pre = document.createElement('pre');
        pre.style = 'margin-top:0.75rem;font-size:0.75rem;color:#94a3b8;white-space:pre-wrap;max-height:300px;overflow-y:auto';
        pre.textContent = d.output;
        el.appendChild(pre);
      }
    } else { el.className = 'status err'; el.textContent = '❌ ' + (d.error || 'Failed') + (d.hint ? ' — ' + d.hint : ''); }
  } catch(e) { el.className = 'status err'; el.textContent = '❌ ' + e.message; }
}
</script>
</body>
</html>`;
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(html);
}

// ── Request Router ────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  const urlPath = parseUrlPath(req.url);

  // Health check — unauthenticated, returns minimal read-only info only
  // Does NOT expose backup dir path or file listings (those require auth)
  if (req.method === 'GET' && urlPath === '/health') {
    return json(res, 200, { status: 'ok', service: 'myclaw-backup' });
  }

  // Auth
  if (!checkAuth(req)) {
    return json(res, 401, { error: 'Unauthorized. Pass ?token=xxx or Authorization: Bearer xxx' });
  }

  // GET / — Web UI
  if (req.method === 'GET' && urlPath === '/') {
    return serveUI(req, res);
  }

  // GET /backups — list
  if (req.method === 'GET' && urlPath === '/backups') {
    return json(res, 200, { backups: listBackups() });
  }

  // POST /backup — create new backup
  if (req.method === 'POST' && urlPath === '/backup') {
    try {
      execSync(`chmod +x "${BACKUP_SCRIPT}"`, { stdio: 'ignore' });
      const output = execSync(`bash "${BACKUP_SCRIPT}" "${BACKUP_DIR}"`, {
        encoding: 'utf8',
        timeout: 120000
      });
      const backups = listBackups();
      const latest = backups[0];
      return json(res, 200, {
        message: 'Backup created',
        filename: latest?.filename,
        size: latest?.sizeHuman,
        downloadUrl: latest?.downloadUrl,
        output: output.replace(/\x1b\[[0-9;]*m/g, '') // strip ANSI
      });
    } catch (e) {
      return json(res, 500, { error: e.message, output: e.stdout });
    }
  }

  // GET /download/:filename
  if (req.method === 'GET' && urlPath.startsWith('/download/')) {
    const filename = path.basename(decodeURIComponent(urlPath.slice('/download/'.length)));
    const filePath = path.join(BACKUP_DIR, filename);
    if (!fs.existsSync(filePath) || !filename.endsWith('.tar.gz')) {
      return json(res, 404, { error: 'File not found' });
    }
    const stat = fs.statSync(filePath);
    res.writeHead(200, {
      'Content-Type': 'application/gzip',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Content-Length': stat.size
    });
    fs.createReadStream(filePath).pipe(res);
    return;
  }

  // POST /upload — upload backup file
  if (req.method === 'POST' && urlPath === '/upload') {
    parseMultipart(req, (err, file) => {
      if (err) return json(res, 400, { error: err.message });
      if (!file.filename.endsWith('.tar.gz')) {
        return json(res, 400, { error: 'Only .tar.gz files accepted' });
      }
      const dest = path.join(BACKUP_DIR, path.basename(file.filename));
      fs.writeFileSync(dest, file.data);
      fs.chmodSync(dest, 0o600);
      return json(res, 200, {
        message: 'Upload successful',
        filename: file.filename,
        size: formatBytes(file.data.length),
        restoreUrl: `/restore/${file.filename}${TOKEN ? '?token=' + TOKEN : ''}`
      });
    });
    return;
  }

  // POST /restore/:filename[?dry_run=1&confirm=1]
  // Non-dry-run restore requires ?confirm=1 to prevent accidental overwrites
  if (req.method === 'POST' && urlPath.startsWith('/restore/')) {
    const filename = path.basename(decodeURIComponent(urlPath.slice('/restore/'.length)));
    const filePath = path.join(BACKUP_DIR, filename);
    const params = new URL('http://x' + req.url).searchParams;
    const isDryRun = params.get('dry_run') === '1';
    const isConfirmed = params.get('confirm') === '1';

    if (!fs.existsSync(filePath)) {
      return json(res, 404, { error: 'Backup file not found: ' + filename });
    }

    // Require explicit confirm=1 for destructive restores
    if (!isDryRun && !isConfirmed) {
      return json(res, 400, {
        error: 'Restore requires explicit confirmation.',
        hint: 'First run with ?dry_run=1 to preview, then add ?confirm=1 to apply.',
        dryRunUrl: `/restore/${filename}?dry_run=1`,
        confirmUrl: `/restore/${filename}?confirm=1`
      });
    }

    try {
      execSync(`chmod +x "${RESTORE_SCRIPT}"`, { stdio: 'ignore' });
      // Pass 'yes' via stdin to satisfy the interactive confirmation in restore.sh
      const cmd = isDryRun
        ? `bash "${RESTORE_SCRIPT}" "${filePath}" --dry-run`
        : `echo 'yes' | bash "${RESTORE_SCRIPT}" "${filePath}"`;
      const output = execSync(cmd, { encoding: 'utf8', timeout: 180000 });
      return json(res, 200, {
        message: isDryRun ? 'Dry run complete' : 'Restore complete',
        dryRun: isDryRun,
        output: output.replace(/\x1b\[[0-9;]*m/g, '')
      });
    } catch (e) {
      return json(res, 500, { error: e.message, output: (e.stdout || '').replace(/\x1b\[[0-9;]*m/g, '') });
    }
  }

  json(res, 404, { error: 'Not found' });
});

// ── Start ─────────────────────────────────────────────────────────────────────
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🦞 OpenClaw Backup Server (token protected)`);
  console.log(`   http://localhost:${PORT}/?token=${TOKEN}`);
  console.log(`   Backup dir: ${BACKUP_DIR}`);
  console.log(`   ⚠️  Do not expose this port to the public internet without TLS.`);
  console.log('');
});

server.on('error', err => {
  console.error('Server error:', err.message);
  process.exit(1);
});
