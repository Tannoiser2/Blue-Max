import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.PW);
import http from 'http'; import fs from 'fs'; import path from 'path';
const dir = path.resolve('build/web');
const tipi = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.ttf': 'font/ttf', '.webp': 'image/webp', '.png': 'image/png', '.jpg': 'image/jpeg' };
http.createServer((req, res) => { let p = decodeURIComponent(req.url.split('?')[0]); const f = path.join(dir, p);
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { 'Content-Type': tipi[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(res); }).listen(8766);
const browser = await chromium.launch({ executablePath: process.env.CHROME });
const ctx = await browser.newContext();
const host = await ctx.newPage();
await host.goto('http://localhost:8766/img/icona.png?rete=locale');
await host.evaluate(async () => {
  const m = await import('/js/rete.js');
  window.R = m.creaRete(); window.RAD = m.RADICE; await window.R.init();
  await window.R.set(`${m.RADICE}/ABCD/host`, { uid: 'h' });
});
const tel = await ctx.newPage();
const [W, H] = (process.env.DIM || '375x667').split('x').map(Number);
await tel.setViewportSize({ width: W, height: H });
await tel.goto('http://localhost:8766/telefono.html?s=ABCD&rete=locale');
await tel.fill('#nome', 'Marco'); await tel.click('#entra'); await tel.waitForTimeout(4500);
const man = ['2A1','3A2','4A3','5A4','6A1','7A1','8S1','8D1','10S1','10D1','12A2','13A2','14S2','14D2','16S2','16D2','17S2','17D2','18A3','19A3','20S3','20D3','21S3','21D3','22S3','22D3','25A4','26A4','29A2','30S2','30D2','32A3','33A3','34A3','35A3','36S3','36D3','1A1','0A2'];
for (const tipo of ['fuoco', 'manovra']) {
  await host.evaluate(async ([tipo, man]) => {
    const seats = await window.R.get(`${window.RAD}/ABCD/seats`);
    const uid = Object.keys(seats)[0];
    const a = (id, lato, q, r, p, extra) => ({ id, pilota: id ? 'Lt. Marco' : 'Ltn. Wolff', nome: id ? 'Spad XIII' : 'Albatros D.V', tipo: 'x', lato, q, r, prua: p, quota: 2, stato: 'volo', ali: 20, fus: 18, coda: 5, motore: 7, tot: { ali: 24, fus: 20, coda: 6, motore: 8 }, carb: 40, manovre: man, ...extra });
    const opz = tipo === 'fuoco' ? [{ a: 0, nome: 'Ltn. Wolff', tipo: 'Albatros D.V', arma: 'pilota', distanza: 1, valori: { corta: 7, media: 9, lunga: 11 } },
      { a: 2, nome: 'Vzfw. Hahn', tipo: 'Pfalz D.III', arma: 'pilota', distanza: 3, valori: { corta: 3, media: 5, lunga: 7 } }]
      : man.slice(0, 30).flatMap((c) => [{ codice: c, quota: 0 }, { codice: c, quota: 1 }]);
    const st = { turno: 3, aerei: [a(0, 'G', 3, 6, 5), a(1, 'A', 3, 7, 5, { uid, controllo: 'telefono' }), a(2, 'G', 5, 5, 4)], richieste: { 1: { tipo, opzioni: opz, info: tipo === 'manovra' ? 'Il nemico in coda ha scelto: a destra, cabrata.' : undefined } },
      diario: ['Turno 2: Wolff spara a Marco, raffica media: 2 pedine', 'Marco perde 3 punti ali'] };
    await window.R.set(`${window.RAD}/ABCD/game`, { t: [JSON.stringify(st)] });
  }, [tipo, man]);
  await tel.waitForTimeout(800);
  if (tipo === 'fuoco') await tel.click('button[data-r="media"]');
  else await tel.click('.man[data-c="14D2"]');
  await tel.waitForTimeout(300);
  await tel.screenshot({ path: `/tmp/finto_${tipo}_${W}.png` });
}
await tel.click('button[data-tab="mappa"]'); await tel.waitForTimeout(800); await tel.screenshot({ path: `/tmp/finto_mappa_${W}.png` });
await browser.close(); process.exit(0);
