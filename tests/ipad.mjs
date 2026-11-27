// Prova al tocco come su iPad: bottoni del menu e campi di testo
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PW);
import http from 'http'; import fs from 'fs'; import path from 'path';
const dir = path.resolve(process.argv[2] || 'build/web');
const tipi = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.pck': 'application/octet-stream', '.css': 'text/css', '.ttf': 'font/ttf', '.webp': 'image/webp', '.png': 'image/png', '.jpg': 'image/jpeg' };
http.createServer((req, res) => { const f = path.join(dir, decodeURIComponent(req.url.split('?')[0]) === '/' ? 'index.html' : decodeURIComponent(req.url.split('?')[0]));
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': tipi[path.extname(f)] || 'application/octet-stream', 'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp' }); fs.createReadStream(f).pipe(res); }).listen(8767);
const browser = await chromium.launch({ executablePath: process.env.CHROME, args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const ctx = await browser.newContext({ viewport: { width: 1180, height: 820 }, hasTouch: true, isMobile: false });
const p = await ctx.newPage();
p.on('dialog', async (d) => { console.log('PROMPT', d.message()); await d.accept('ABCD'); });
await p.goto('http://localhost:8767/index.html?rete=locale');
await p.waitForTimeout(25000);
await p.screenshot({ path: '/tmp/ipad0.png' });
const tap = async (x, y, f) => { await p.touchscreen.tap(x, y); await p.waitForTimeout(2500); if (f) await p.screenshot({ path: '/tmp/' + f + '.png' }); };
const [x, y] = (process.env.XY || '200,500').split(',').map(Number);
await tap(x, y, 'ipad1');
const [x2, y2] = (process.env.XY2 || '0,0').split(',').map(Number);
if (x2) await tap(x2, y2, 'ipad2');
const [x3, y3] = (process.env.XY3 || '0,0').split(',').map(Number);
if (x3) await tap(x3, y3, 'ipad3');
await browser.close(); process.exit(0);
