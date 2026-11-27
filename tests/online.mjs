// Prova online: un computer ospita (Spad pilotato da remoto contro Fokker del computer), un altro entra con il gioco completo.
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PW || 'playwright');
import http from 'http';
import fs from 'fs';
import path from 'path';
const dir = path.resolve(process.argv[2] || 'build/web');
const out = path.resolve(process.argv[3] || '/tmp/prova_online');
const DURATA = Number(process.argv[4] || 200) * 1000;
fs.mkdirSync(out, { recursive: true });
const tipi = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream',
  '.css': 'text/css', '.ttf': 'font/ttf', '.webp': 'image/webp', '.png': 'image/png', '.jpg': 'image/jpeg' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const f = path.join(dir, p);
  if (!fs.existsSync(f)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': tipi[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
}).listen(8766);
const browser = await chromium.launch({ executablePath: process.env.CHROME || undefined, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const ctx = await browser.newContext();
const host = await ctx.newPage({ viewport: { width: 1280, height: 720 } });
let codice = '';
const errori = [];
let risposte = 0;
host.on('console', (m) => { const k = /STANZA (\w{4})/.exec(m.text()); if (k) codice = k[1]; if (/SCRIPT ERROR/.test(m.text())) errori.push('host: ' + m.text()); });
await host.goto('http://localhost:8766/index.html?rete=locale&prova=telefono');
for (let i = 0; i < 120 && !codice; i++) await host.waitForTimeout(1000);
console.log('codice', codice);
const osp = await ctx.newPage({ viewport: { width: 1280, height: 720 } });
osp.on('console', (m) => { if (/OSPITE risponde/.test(m.text())) risposte++; if (/SCRIPT ERROR/.test(m.text())) errori.push('ospite: ' + m.text()); });
osp.on('pageerror', (e) => errori.push('ospite: ' + e));
await osp.goto(`http://localhost:8766/index.html?rete=locale&entra=${codice}&nome=Marco&auto=1`);
const t0 = Date.now();
let foto = 0;
while (Date.now() - t0 < DURATA) {
  await osp.waitForTimeout(15000);
  await osp.screenshot({ path: `${out}/ospite${foto}.png` });
  await host.screenshot({ path: `${out}/host${foto}.png` });
  foto++;
}
console.log('risposte dell\'ospite', risposte);
console.log('errori', errori.length, errori.slice(0, 10).join('\n'));
await browser.close();
process.exit(0);
