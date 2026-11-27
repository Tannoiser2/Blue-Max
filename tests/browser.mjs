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
await tv.goto('http://localhost:8765/index.html?rete=locale&prova=telefono' + (process.env.DIETRO ? '&dietro=1' : ''));
for (let i = 0; i < 120 && !codice; i++) await tv.waitForTimeout(1000);
console.log('codice', codice);
await tv.screenshot({ path: out + '/tv0.png' });
const tel = await ctx.newPage();
await tel.setViewportSize({ width: Number(process.env.TW || 390), height: Number(process.env.TH || 700) });
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
    const dritta = process.env.DIETRO ? ((await tel.$('.man[data-c="2A1"]:not(.no)')) || man[0]) : man[Math.floor(Math.random() * man.length)];
    await dritta.click();
    await tel.waitForTimeout(200);
    if (foto < 1) {
      await tel.screenshot({ path: out + '/telefono_manovra.png' }); foto++;
      for (const t of ['aereo', 'mappa']) { await tel.click(`button[data-tab="${t}"]`); await tel.waitForTimeout(300); await tel.screenshot({ path: out + '/telefono_' + t + '.png' }); }
      await tel.click('button[data-tab="azione"]'); await tel.waitForTimeout(200);
      await (await tel.$$('.man:not(.no)'))[0].click(); await tel.waitForTimeout(200);
    }
    const inv = await tel.$('#invia:not([disabled])');
    if (inv) { await inv.click(); mosse++; }
    continue;
  }
  const b = await tel.$('button[data-r="media"]');
  if (b) {
    await b.click();
    await tel.screenshot({ path: out + '/telefono_fuoco.png' });
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
