// Prova nel browser: schermo grande (Godot web) + un telefono che pilota uno Spad, collegati con la rete "locale".
// PW=/percorso/playwright-core CHROME=/usr/bin/google-chrome node tests/browser.mjs build/web /tmp/prova_web 150
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PW || 'playwright');
import http from 'http';
import fs from 'fs';
import path from 'path';

const dir = path.resolve(process.argv[2] || 'build/web');
const out = path.resolve(process.argv[3] || '/tmp/prova_web');
const DURATA = Number(process.argv[4] || 150) * 1000;
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
}).listen(8765);

const browser = await chromium.launch({ executablePath: process.env.CHROME || undefined, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
const ctx = await browser.newContext();
const tv = await ctx.newPage({ viewport: { width: 1600, height: 900 } });
let codice = '';
const errori = [];
tv.on('console', (m) => {
  const t = m.text();
  const k = /STANZA (\w{4})/.exec(t);
  if (k) codice = k[1];
  if (m.type() === 'error' || /SCRIPT ERROR|ERROR:/.test(t)) errori.push(t);
});
tv.on('pageerror', (e) => errori.push(String(e)));
await tv.goto('http://localhost:8765/index.html?rete=locale&prova=telefono');
for (let i = 0; i < 120 && !codice; i++) await tv.waitForTimeout(1000);
console.log('codice', codice);
await tv.screenshot({ path: out + '/tv0.png' });
const tel = await ctx.newPage({ viewport: { width: 400, height: 860 }, isMobile: true, hasTouch: true });
tel.on('pageerror', (e) => errori.push('telefono: ' + e));
await tel.goto(`http://localhost:8765/telefono.html?s=${codice}&rete=locale`);
await tel.fill('#nome', 'Marco');
await tel.click('#entra');
const t0 = Date.now();
let mosse = 0, spari = 0, foto = 0;
while (Date.now() - t0 < DURATA) {
  await tel.waitForTimeout(1500);
  const man = await tel.$$('.man:not(.no)');
  if (man.length && await tel.$('#invia')) {
    await man[Math.floor(man.length / 2)].click();
    await tel.waitForTimeout(200);
    if (foto < 1) { await tel.screenshot({ path: out + '/telefono_manovra.png', fullPage: true }); foto++; }
    const inv = await tel.$('#invia:not([disabled])');
    if (inv) { await inv.click(); mosse++; }
    continue;
  }
  const b = await tel.$('button[data-r="media"]');
  if (b) {
    await b.click();
    await tel.screenshot({ path: out + '/telefono_fuoco.png', fullPage: true });
    await tel.click('#spara');
    spari++;
    continue;
  }
  if (mosse === 3 && foto < 2) { await tv.screenshot({ path: out + '/tv_partita.png' }); foto++; }
}
await tv.screenshot({ path: out + '/tv_fine.png' });
await tel.screenshot({ path: out + '/telefono_fine.png', fullPage: true });
console.log('manovre dal telefono', mosse, 'spari', spari);
console.log('errori', errori.length, errori.slice(0, 15).join('\n'));
await browser.close();
process.exit(0);
