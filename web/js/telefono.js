// La cloche del pilota: entra nella stanza con il QR code e sceglie da qui, in segreto, manovra e raffica.
// Il cielo, gli spari e le animazioni restano sullo schermo grande; qui c'è anche una piccola mappa.
import { creaRete, RADICE, unisci } from './rete.js';
import { sbloccaAudio, suona } from './suoni.js';

const q = new URLSearchParams(location.search);
const app = document.getElementById('app');
const QUOTE = ['Molto Bassa', 'Bassa', 'Media', 'Alta', 'Molto Alta'];
const S3 = Math.sqrt(3);
// geometria delle manovre (versione Sinistra): passi relativi alla prua e rotazione finale
const GEO = {
  0: [[], 0], 1: [[], -1], 2: [[0], 0], 3: [[0, 0], 0], 4: [[0, 0, 0], 0], 5: [[0, 0, 0, 0], 0], 6: [[0], -1], 7: [[0], 1], 8: [[-1], -1], 9: [[-1], -2],
  10: [[-1], 0], 11: [[-1], 3], 12: [[0, 0], -1], 13: [[0, 0], 1], 14: [[0, -1], -1], 15: [[0, -1], -2], 16: [[-1, -1], -1], 17: [[-1, -1], 0],
  18: [[0, 0, 0], -1], 19: [[0, 0, 0], 1], 20: [[0, 0, -1], -1], 21: [[0, -1, -1], -1], 22: [[0, -1, -1], -2], 23: [[0, -1, -2], -2], 24: [[0, -1, -2], 3],
  25: [[0, 0, 0, 0], -1], 26: [[0, 0, 0, 0], 1], 27: [[], 3], 28: [[], -2], 29: [[0], 3], 30: [[0], -2], 31: [[-1], 1], 32: [[0, 0], -2], 33: [[0, 0], 2],
  34: [[0, -1], 0], 35: [[0, 1], 0], 36: [[-1, 0], 1],
};
const NONRIP = [1, 28, 31, 36];

let rete = null;
let uid = '';
let codice = (q.get('s') || '').toUpperCase().slice(0, 4);
let nome = '';
try { nome = localStorage.getItem('bm_nome') || ''; } catch (e) { /* ok */ }
let stato = null;
let mio = null;          // il mio aereo
let scelta = { codice: '', quota: 0 };
let fuoco = {};          // arma -> {a, raffica}
let inviato = '';        // chiave della richiesta a cui ho già risposto
let errore = '';
const mappaImg = new Image();
mappaImg.src = 'img/mappa.jpg';
mappaImg.onload = () => disegnaMappa();

function esc(s) { return String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c])); }
function parse(c) {
  const m = /^(\d+)([SAD])(\d)$/.exec(c);
  return m ? { n: +m[1], dir: m[2], vel: +m[3] } : { n: 0, dir: 'A', vel: 2 };
}
function geo(c) {
  const k = parse(c);
  let [passi, prua] = GEO[k.n] || [[], 0];
  passi = passi.slice();
  if (k.dir === 'D') { passi = passi.map((p) => (Math.abs(p) === 3 ? 3 : -p)); prua = Math.abs(prua) === 3 ? 3 : -prua; }
  if (k.n === 1 && k.dir === 'A') prua = 0;
  return { ...k, passi, prua };
}

function accesso() {
  app.innerHTML = `
    <h1>Blue Max</h1>
    <div class="carta">
      <h2>Entra in squadriglia</h2>
      <p class="nota">Scrivi il codice della stanza che vedi sullo schermo grande e il tuo nome.</p>
      <p><input id="cod" maxlength="4" placeholder="Codice (4 lettere)" value="${esc(codice)}" autocapitalize="characters"></p>
      <p><input id="nome" maxlength="16" placeholder="Il tuo nome" value="${esc(nome)}"></p>
      <button id="entra" class="largo">DECOLLA</button>
      <p class="nota">${esc(errore)}</p>
    </div>`;
  document.getElementById('entra').onclick = entra;
}

async function entra() {
  sbloccaAudio();
  codice = document.getElementById('cod').value.trim().toUpperCase();
  nome = document.getElementById('nome').value.trim() || 'Pilota';
  try { localStorage.setItem('bm_nome', nome); } catch (e) { /* ok */ }
  try {
    if (!rete) { rete = creaRete(); uid = await rete.init(); }
    const h = await rete.get(`${RADICE}/${codice}/host`);
    if (!h) { errore = 'La stanza ' + codice + ' non esiste.'; accesso(); return; }
    await rete.set(`${RADICE}/${codice}/seats/${uid}`, { uid, name: nome });
    rete.on(`${RADICE}/${codice}/game`, (v) => {
      const j = unisci(v);
      if (!j) return;
      try { stato = JSON.parse(j); } catch (e) { return; }
      aggiorna();
    });
    app.innerHTML = '<h1>Blue Max</h1><div class="carta"><h2>Sei dentro!</h2><p class="nota">Aspetta che la partita cominci sullo schermo grande.</p></div>';
  } catch (e) {
    errore = 'Problema di collegamento: ' + (e?.message || e);
    accesso();
  }
}

function aggiorna() {
  mio = (stato.aerei || []).find((a) => a.uid === uid && a.controllo === 'telefono') || null;
  const rich = mio ? (stato.richieste || {})[String(mio.id)] : null;
  const chiave = rich ? `${stato.turno}-${rich.tipo}` : '';
  if (rich && chiave !== inviato && !document.getElementById('scelta')) {
    scelta = { codice: '', quota: 0 };
    fuoco = {};
    suona('tocca');
    if (navigator.vibrate) navigator.vibrate(120);
  }
  disegna(rich, chiave);
}

function barra(n, v, t) {
  const p = Math.max(0, Math.min(100, (100 * v) / Math.max(1, t)));
  return `<div>${n} ${v}</div><div class="barra"><i style="width:${p}%"></i></div>`;
}

function disegna(rich, chiave) {
  if (!mio) {
    app.innerHTML = `<h1>Blue Max</h1><div class="carta"><h2>Ciao ${esc(nome)}</h2><p class="nota">Lo schermo grande non ti ha ancora affidato un aereo, oppure la partita non è cominciata.</p></div>`;
    return;
  }
  let h = `<h1>Blue Max</h1>
    <div class="carta"><h2>${esc(mio.pilota)} - ${esc(mio.nome)}</h2>
    <div class="nota">Turno ${stato.turno} - quota ${QUOTE[mio.quota]} - carburante ${mio.carb} - ultima manovra ${esc(mio.ultima || '-')}</div>
    <div class="barre">${barra('Ali', mio.ali, mio.tot?.ali)}${barra('Fusoliera', mio.fus, mio.tot?.fus)}${barra('Coda', mio.coda, mio.tot?.coda)}${barra('Motore', mio.motore, mio.tot?.motore)}</div>
    ${mio.fuoco ? '<div class="avviso">Sei in fiamme!</div>' : ''}${mio.fumo ? '<div class="avviso">Perdi fumo.</div>' : ''}
    ${mio.stato !== 'volo' ? `<div class="avviso">Stato: ${esc(mio.stato)}</div>` : ''}
    </div>
    <canvas id="mappa" width="600" height="420"></canvas>`;
  if (rich && chiave === inviato) {
    h += '<div class="carta"><h2>Fatto!</h2><p class="nota">Aspetta gli altri piloti.</p></div>';
  } else if (rich && rich.tipo === 'manovra') {
    h += pannelloManovra(rich);
  } else if (rich && rich.tipo === 'fuoco') {
    h += pannelloFuoco(rich);
  } else {
    h += `<div class="carta"><p class="nota">${stato.finita ? 'Il combattimento è finito.' : 'Guarda lo schermo grande: tocca agli altri.'}</p></div>`;
  }
  h += `<div class="carta diario">${(stato.diario || []).map(esc).join('<br>')}</div>`;
  app.innerHTML = h;
  disegnaMappa();
  collega(rich, chiave);
}

function pannelloManovra(rich) {
  const ops = rich.opzioni || [];
  const codici = [...new Set(ops.map((o) => o.codice))];
  const gruppi = {};
  for (const c of mio.manovre.concat(codici.filter((c) => !mio.manovre.includes(c)))) {
    const k = parse(c);
    const g = c === '0A2' ? 'Avvitamento' : k.n >= 27 ? 'Acrobatiche' : k.n <= 1 ? 'Rotazioni e stallo' : 'Velocità ' + k.vel;
    (gruppi[g] = gruppi[g] || []).push(c);
  }
  let h = '<div class="carta" id="scelta"><h2>Scegli la manovra</h2>';
  if (rich.info) h += `<div class="avviso">${esc(rich.info)}</div>`;
  for (const g of ['Avvitamento', 'Rotazioni e stallo', 'Velocità 1', 'Velocità 2', 'Velocità 3', 'Velocità 4', 'Acrobatiche']) {
    if (!gruppi[g]) continue;
    h += `<div class="gruppo">${g}</div><div class="manovre">`;
    for (const c of gruppi[g]) {
      const ok = codici.includes(c);
      const k = parse(c);
      h += `<div class="man ${ok ? '' : 'no'} ${scelta.codice === c ? 'sel' : ''}" data-c="${c}"><canvas width="132" height="144" data-g="${c}"></canvas>${NONRIP.includes(k.n) ? '(' + c + ')' : c}</div>`;
    }
    h += '</div>';
  }
  const quote = new Set(ops.filter((o) => o.codice === scelta.codice).map((o) => +o.quota));
  h += '<div class="riga" style="margin-top:10px">';
  for (const [d, t] of [[1, 'Cabrata'], [0, 'Stessa quota'], [-1, 'Picchiata']]) {
    h += `<button data-q="${d}" ${quote.has(d) ? '' : 'disabled'} class="${scelta.quota === d && quote.has(d) ? 'sel' : ''}">${t}</button>`;
  }
  h += `</div><button id="invia" class="largo" ${scelta.codice && quote.has(scelta.quota) ? '' : 'disabled'}>CONFERMA ${esc(scelta.codice)}</button></div>`;
  return h;
}

function pannelloFuoco(rich) {
  let h = '<div class="carta" id="scelta"><h2>Fuoco!</h2><p class="nota">Scegli bersaglio e raffica. Il numero è il valore di fuoco.</p>';
  for (const o of rich.opzioni || []) {
    h += `<div class="gruppo">${esc(o.nome)} (${esc(o.tipo)}) - ${o.arma === 'pilota' ? 'mitragliatrici' : 'osservatore'}, distanza ${o.distanza}</div><div class="riga">`;
    for (const r of ['corta', 'media', 'lunga']) {
      if (o.valori[r] === undefined) continue;
      const sel = fuoco[o.arma] && fuoco[o.arma].a === o.a && fuoco[o.arma].raffica === r;
      h += `<button data-a="${o.a}" data-arma="${o.arma}" data-r="${r}" class="${sel ? 'sel' : ''}">${r} ${o.valori[r]}</button>`;
    }
    h += '</div>';
  }
  h += '<div class="riga" style="margin-top:10px"><button id="nonspara">Non sparare</button><button id="spara">FUOCO!</button></div></div>';
  return h;
}

function collega(rich, chiave) {
  document.querySelectorAll('canvas[data-g]').forEach(disegnaManovra);
  document.querySelectorAll('.man').forEach((el) => {
    el.onclick = () => {
      if (el.classList.contains('no')) return;
      scelta.codice = el.dataset.c;
      const quote = (rich.opzioni || []).filter((o) => o.codice === scelta.codice).map((o) => +o.quota);
      if (!quote.includes(scelta.quota)) scelta.quota = quote.includes(0) ? 0 : quote[0];
      disegna(rich, chiave);
    };
  });
  document.querySelectorAll('button[data-q]').forEach((b) => { b.onclick = () => { scelta.quota = +b.dataset.q; disegna(rich, chiave); }; });
  const inv = document.getElementById('invia');
  if (inv) inv.onclick = () => { invia('manovra', { id: mio.id, codice: scelta.codice, quota: scelta.quota }, chiave, rich); };
  document.querySelectorAll('button[data-arma]').forEach((b) => {
    b.onclick = () => {
      const a = +b.dataset.a, arma = b.dataset.arma, r = b.dataset.r;
      if (fuoco[arma] && fuoco[arma].a === a && fuoco[arma].raffica === r) delete fuoco[arma]; else fuoco[arma] = { a, raffica: r };
      disegna(rich, chiave);
    };
  });
  const sp = document.getElementById('spara');
  if (sp) sp.onclick = () => invia('fuoco', { id: mio.id, lista: Object.entries(fuoco).map(([arma, x]) => ({ arma, a: x.a, raffica: x.raffica })) }, chiave, rich);
  const ns = document.getElementById('nonspara');
  if (ns) ns.onclick = () => invia('fuoco', { id: mio.id, lista: [] }, chiave, rich);
}

function invia(k, v, chiave, rich) {
  rete.push(`${RADICE}/${codice}/acts`, { s: uid, k, v: JSON.stringify(v) });
  inviato = chiave;
  suona('ok');
  disegna(rich, chiave);
}

// la manovra disegnata come sulla Tabella-Movimento: esagoni piatti in alto, freccia e sagoma
function disegnaManovra(cv) {
  const g = geo(cv.dataset.g);
  const x = cv.getContext('2d');
  const L = 16;
  const D = { 0: [0, -S3], 1: [1.5, -S3 / 2], 2: [1.5, S3 / 2], 3: [0, S3], '-2': [-1.5, S3 / 2], '-1': [-1.5, -S3 / 2] };
  let p = [0, 0];
  const pts = [p];
  for (const s of g.passi) { const d = D[s === -3 ? 3 : s]; p = [p[0] + d[0] * L, p[1] + d[1] * L]; pts.push(p); }
  const tutti = pts.length === 1 ? [[-L, 0], [L, 0]] : pts;
  const xs = tutti.map((a) => a[0]), ys = tutti.map((a) => a[1]);
  const ox = cv.width / 2 - (Math.min(...xs) + Math.max(...xs)) / 2, oy = cv.height / 2 - (Math.min(...ys) + Math.max(...ys)) / 2;
  x.strokeStyle = '#2a2118';
  x.lineWidth = 2;
  for (const c of tutti) {
    x.beginPath();
    for (let k = 0; k <= 6; k++) { const a = (Math.PI / 3) * k; x.lineTo(c[0] + ox + Math.cos(a) * L, c[1] + oy + Math.sin(a) * L); }
    x.stroke();
  }
  const c0 = pts.length === 1 ? tutti[1] : tutti[0];
  x.beginPath(); x.moveTo(c0[0] + ox - 6, c0[1] + oy + 4); x.lineTo(c0[0] + ox, c0[1] + oy - 5); x.lineTo(c0[0] + ox + 6, c0[1] + oy + 4); x.stroke();
  const cf = pts.length === 1 ? tutti[0] : tutti[tutti.length - 1];
  const a = (g.prua * Math.PI) / 3;
  const su = [Math.sin(a), -Math.cos(a)], dx = [Math.cos(a), Math.sin(a)], k = L * 0.75;
  const P = (u, v) => [cf[0] + ox + su[0] * u + dx[0] * v, cf[1] + oy + su[1] * u + dx[1] * v];
  x.lineWidth = 4;
  const linea = (a1, a2) => { x.beginPath(); x.moveTo(...a1); x.lineTo(...a2); x.stroke(); };
  linea(P(k * 0.55, -k), P(k * 0.55, k));
  linea(P(k * 0.9, 0), P(-k * 0.8, 0));
  linea(P(-k * 0.8, -k * 0.4), P(-k * 0.8, k * 0.4));
}

// piccola mappa: foto della mappa con gli aerei, la freccia della prua e la quota
function disegnaMappa() {
  const cv = document.getElementById('mappa');
  if (!cv || !stato) return;
  const x = cv.getContext('2d');
  const W = 18.95, H = 23.3, O = [-2.75, -1.8];
  // si inquadra la zona degli aerei in volo
  const vivi = stato.aerei.filter((a) => ['volo', 'vite', 'planata'].includes(a.stato));
  const cen = (a) => [S3 * (a.q + a.r * 0.5) - O[0], 1.5 * a.r - O[1]];
  let minx = W, maxx = 0, miny = H, maxy = 0;
  for (const a of vivi) { const [cx, cy] = cen(a); minx = Math.min(minx, cx); maxx = Math.max(maxx, cx); miny = Math.min(miny, cy); maxy = Math.max(maxy, cy); }
  if (!vivi.length) { minx = 0; maxx = W; miny = 0; maxy = H; }
  const m = 3.2;
  let w = Math.max(maxx - minx + 2 * m, 8), hh = Math.max(maxy - miny + 2 * m, 6);
  const ar = cv.width / cv.height;
  if (w / hh > ar) hh = w / ar; else w = hh * ar;
  const sx = (minx + maxx) / 2 - w / 2, sy = (miny + maxy) / 2 - hh / 2;
  const k = cv.width / w;
  x.fillStyle = '#3b2f22';
  x.fillRect(0, 0, cv.width, cv.height);
  if (mappaImg.complete && mappaImg.naturalWidth) {
    const ik = mappaImg.naturalWidth / W;
    x.drawImage(mappaImg, sx * ik, sy * ik, w * ik, hh * ik, 0, 0, cv.width, cv.height);
  }
  for (const a of vivi) {
    const [cx, cy] = cen(a);
    const px = (cx - sx) * k, py = (cy - sy) * k;
    const col = a.lato === 'G' ? '#b8322a' : '#2e6aa8';
    x.save();
    x.translate(px, py);
    x.rotate((a.prua * Math.PI) / 3);
    x.fillStyle = col;
    x.strokeStyle = a === mio || (mio && a.id === mio.id) ? '#c9a23c' : '#fff';
    x.lineWidth = 3;
    x.beginPath(); x.moveTo(k * 0.55, 0); x.lineTo(-k * 0.4, -k * 0.35); x.lineTo(-k * 0.25, 0); x.lineTo(-k * 0.4, k * 0.35); x.closePath();
    x.fill(); x.stroke();
    x.restore();
    x.font = '600 16px Oswald';
    x.fillStyle = '#fff';
    x.strokeStyle = '#000';
    x.lineWidth = 4;
    const t = `${a.pilota.split(' ').slice(-1)[0]} ${['BB', 'B', 'M', 'A', 'MA'][a.quota]}`;
    x.strokeText(t, px - 30, py - k * 0.55);
    x.fillText(t, px - 30, py - k * 0.55);
  }
}

if (codice.length === 4 && nome && q.has('subito')) entra(); else accesso();
