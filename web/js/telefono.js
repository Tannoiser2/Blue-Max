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

let tab = 'azione';       // scheda visibile: azione, aereo, mappa
let ultimaRich = '';

function aggiorna() {
  mio = (stato.aerei || []).find((a) => a.uid === uid && a.controllo === 'telefono') || null;
  const rich = mio ? (stato.richieste || {})[String(mio.id)] : null;
  const chiave = rich ? `${stato.turno}-${rich.tipo}` : '';
  if (rich && chiave !== inviato && chiave !== ultimaRich) {
    ultimaRich = chiave;
    scelta = { codice: '', quota: 0 };
    fuoco = {};
    tab = 'azione';
    suona('tocca');
    if (navigator.vibrate) navigator.vibrate(120);
  }
  disegna(rich, chiave);
}

function barra(n, v, t) {
  const p = Math.max(0, Math.min(100, (100 * v) / Math.max(1, t)));
  return `<div class="bn">${n} <b>${v}</b></div><div class="barra"><i style="width:${p}%"></i></div>`;
}

let ultimo = [null, ''];
function disegna(rich, chiave) {
  ultimo = [rich, chiave];
  if (!mio) {
    app.innerHTML = `<h1>Blue Max</h1><div class="carta"><h2>Ciao ${esc(nome)}</h2><p class="nota">Lo schermo grande non ti ha ancora affidato un aereo, oppure la partita non è cominciata.</p></div>`;
    return;
  }
  const daFare = rich && chiave !== inviato;
  const nomeAz = rich && rich.tipo === 'fuoco' ? 'Fuoco' : 'Manovra';
  let corpo = '';
  if (tab === 'aereo') corpo = pannelloAereo();
  else if (tab === 'mappa') corpo = '<canvas id="mappa"></canvas>';
  else if (rich && chiave === inviato) corpo = '<div class="attesa"><h2>Fatto!</h2><p class="nota">Aspetta gli altri piloti.</p></div>';
  else if (rich && rich.tipo === 'manovra') corpo = pannelloManovra(rich);
  else if (rich && rich.tipo === 'fuoco') corpo = pannelloFuoco(rich);
  else corpo = `<div class="attesa"><p class="nota">${stato.finita ? 'Il combattimento è finito.' : 'Guarda lo schermo grande: tocca agli altri.'}</p></div>`;
  app.innerHTML = `
    <div class="testa"><span class="pil">${esc(mio.pilota)}</span><span class="dati">${esc(mio.nome)} - turno ${stato.turno} - quota ${QUOTE[mio.quota]}${mio.fuoco ? ' - <b class="rosso">IN FIAMME</b>' : ''}</span></div>
    <div class="corpo" id="corpo">${corpo}</div>
    <div class="schede">
      <button data-tab="azione" class="${tab === 'azione' ? 'sel' : ''}">${nomeAz}${daFare ? ' <span class="pallino">!</span>' : ''}</button>
      <button data-tab="aereo" class="${tab === 'aereo' ? 'sel' : ''}">Aereo</button>
      <button data-tab="mappa" class="${tab === 'mappa' ? 'sel' : ''}">Mappa</button>
    </div>`;
  document.querySelectorAll('button[data-tab]').forEach((b) => { b.onclick = () => { tab = b.dataset.tab; disegna(rich, chiave); }; });
  if (tab === 'mappa') {
    const cv = document.getElementById('mappa');
    const r = document.getElementById('corpo').getBoundingClientRect();
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    cv.style.width = r.width + 'px';
    cv.style.height = r.height + 'px';
    cv.width = Math.round(r.width * dpr);
    cv.height = Math.round(r.height * dpr);
    disegnaMappa();
  }
  impagina();
  collega(rich, chiave);
}

function pannelloAereo() {
  const d = (stato.diario || []).slice(-14);
  return `<div class="aereo">
    <div class="nota">Carburante ${mio.carb} - ultima manovra ${esc(mio.ultima || '-')}</div>
    <div class="barre">${barra('Ali', mio.ali, mio.tot?.ali)}${barra('Fusoliera', mio.fus, mio.tot?.fus)}${barra('Coda', mio.coda, mio.tot?.coda)}${barra('Motore', mio.motore, mio.tot?.motore)}</div>
    ${mio.fuoco ? '<div class="avviso">Sei in fiamme!</div>' : ''}${mio.fumo ? '<div class="avviso">Perdi fumo.</div>' : ''}
    ${mio.stato !== 'volo' ? `<div class="avviso">Stato: ${esc(mio.stato)}</div>` : ''}
    <div class="diario">${d.map(esc).join('<br>')}</div></div>`;
}

const GRUPPI = ['Avvitamento', 'Rotazioni e stallo', 'Velocità 1', 'Velocità 2', 'Velocità 3', 'Velocità 4', 'Acrobatiche'];
function pannelloManovra(rich) {
  const ops = rich.opzioni || [];
  const codici = [...new Set(ops.map((o) => o.codice))];
  const gruppi = {};
  for (const c of mio.manovre.concat(codici.filter((c) => !mio.manovre.includes(c)))) {
    const k = parse(c);
    const g = c === '0A2' ? 'Avvitamento' : k.n >= 27 ? 'Acrobatiche' : k.n <= 1 ? 'Rotazioni e stallo' : 'Velocità ' + k.vel;
    (gruppi[g] = gruppi[g] || []).push(c);
  }
  let h = '<div class="pman" id="scelta">';
  if (rich.info) h += `<div class="avviso piccolo">${esc(rich.info)}</div>`;
  h += '<div class="legenda">' + GRUPPI.filter((g) => gruppi[g]).map((g) => `<span class="g${GRUPPI.indexOf(g)}">${g.replace('Velocità ', 'Vel. ').replace('Rotazioni e stallo', 'Rotazioni')}</span>`).join('') + '</div>';
  h += '<div class="manovre" id="griglia">';
  for (const g of GRUPPI) {
    for (const c of gruppi[g] || []) {
      const ok = codici.includes(c);
      const k = parse(c);
      h += `<div class="man g${GRUPPI.indexOf(g)} ${ok ? '' : 'no'} ${scelta.codice === c ? 'sel' : ''}" data-c="${c}"><canvas data-g="${c}"></canvas><span>${NONRIP.includes(k.n) ? '(' + c + ')' : c}</span></div>`;
    }
  }
  h += '</div>';
  const quote = new Set(ops.filter((o) => o.codice === scelta.codice).map((o) => +o.quota));
  h += '<div class="comandi">';
  for (const [d, t] of [[1, 'Cabra'], [0, 'Stessa'], [-1, 'Picchia']]) {
    h += `<button data-q="${d}" ${quote.has(d) ? '' : 'disabled'} class="${scelta.quota === d && quote.has(d) ? 'sel' : ''}">${t}</button>`;
  }
  h += `<button id="invia" class="ok" ${scelta.codice && quote.has(scelta.quota) ? '' : 'disabled'}>OK ${esc(scelta.codice)}</button></div></div>`;
  return h;
}

// la griglia delle manovre riempie la scheda senza scorrere: si sceglie il numero di colonne con le celle più grandi
function impagina() {
  const gr = document.getElementById('griglia');
  if (!gr) return;
  const celle = gr.children;
  const n = celle.length;
  const W = gr.clientWidth, H = gr.clientHeight, gap = 4;
  let best = [4, 0, 0, 0];
  for (let c = 3; c <= 10; c++) {
    const r = Math.ceil(n / c);
    const cw = (W - gap * (c - 1)) / c, ch = (H - gap * (r - 1)) / r;
    const lato = Math.min(cw, ch / 1.15);
    if (lato > best[1]) best = [c, lato, cw, ch];
  }
  const [c, , , ch] = best;
  gr.style.gridTemplateColumns = `repeat(${c}, 1fr)`;
  gr.style.gridAutoRows = `${Math.floor(ch)}px`;
  const dpr = Math.min(2, window.devicePixelRatio || 1);
  const fs = Math.max(11, Math.min(17, Math.floor(ch * 0.16)));
  for (const el of celle) {
    el.querySelector('span').style.fontSize = fs + 'px';
    const cv = el.querySelector('canvas');
    const w = el.clientWidth - 4, h = Math.floor(ch) - fs - 8;
    cv.style.width = w + 'px';
    cv.style.height = Math.max(10, h) + 'px';
    cv.width = Math.round(w * dpr);
    cv.height = Math.round(Math.max(10, h) * dpr);
    disegnaManovra(cv);
  }
}
window.addEventListener('resize', () => { if (stato && mio) disegna(...ultimo); });

function pannelloFuoco(rich) {
  let h = '<div class="pfuoco" id="scelta"><h2>Fuoco!</h2><p class="nota">Scegli bersaglio e raffica. Il numero è il valore di fuoco.</p>';
  for (const o of rich.opzioni || []) {
    h += `<div class="gruppo">${esc(o.nome)} (${esc(o.tipo)}) - ${o.arma === 'pilota' ? 'mitragliatrici' : 'osservatore'}, distanza ${o.distanza}</div><div class="riga">`;
    for (const r of ['corta', 'media', 'lunga']) {
      if (o.valori[r] === undefined) continue;
      const sel = fuoco[o.arma] && fuoco[o.arma].a === o.a && fuoco[o.arma].raffica === r;
      h += `<button data-a="${o.a}" data-arma="${o.arma}" data-r="${r}" class="${sel ? 'sel' : ''}">${r} ${o.valori[r]}</button>`;
    }
    h += '</div>';
  }
  h += '<div class="riga" style="margin-top:auto;padding-top:10px"><button id="nonspara">Non sparare</button><button id="spara">FUOCO!</button></div></div>';
  return h;
}

function collega(rich, chiave) {
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
  const D = { 0: [0, -S3], 1: [1.5, -S3 / 2], 2: [1.5, S3 / 2], 3: [0, S3], '-2': [-1.5, S3 / 2], '-1': [-1.5, -S3 / 2] };
  let p = [0, 0];
  const pts = [p];
  for (const s of g.passi) { const d = D[s === -3 ? 3 : s]; p = [p[0] + d[0], p[1] + d[1]]; pts.push(p); }
  const tutti = pts.length === 1 ? [[-1, 0], [1, 0]] : pts;
  const xs = tutti.map((a) => a[0]), ys = tutti.map((a) => a[1]);
  const bw = Math.max(...xs) - Math.min(...xs) + 2.1, bh = Math.max(...ys) - Math.min(...ys) + S3 + 0.1;
  // scala comune per tutte (la più lunga deve entrare), un po' più grande per le corte
  const base = Math.min(cv.width / 5.2, cv.height / (5 * S3 + 0.2));
  const L = Math.min(cv.width / bw, cv.height / bh, base * 1.35);
  const ox = cv.width / 2 - ((Math.min(...xs) + Math.max(...xs)) / 2) * L, oy = cv.height / 2 - ((Math.min(...ys) + Math.max(...ys)) / 2) * L;
  x.clearRect(0, 0, cv.width, cv.height);
  x.strokeStyle = '#2a2118';
  x.lineWidth = Math.max(1, L / 9);
  for (const c of tutti) {
    x.beginPath();
    for (let k = 0; k <= 6; k++) { const a = (Math.PI / 3) * k; x.lineTo(c[0] * L + ox + Math.cos(a) * L, c[1] * L + oy + Math.sin(a) * L); }
    x.stroke();
  }
  const c0 = pts.length === 1 ? tutti[1] : tutti[0];
  const u = L / 2.7;
  x.beginPath(); x.moveTo(c0[0] * L + ox - u, c0[1] * L + oy + u * 0.7); x.lineTo(c0[0] * L + ox, c0[1] * L + oy - u * 0.8); x.lineTo(c0[0] * L + ox + u, c0[1] * L + oy + u * 0.7); x.stroke();
  const cf = pts.length === 1 ? tutti[0] : tutti[tutti.length - 1];
  const a = (g.prua * Math.PI) / 3;
  const su = [Math.sin(a), -Math.cos(a)], dx = [Math.cos(a), Math.sin(a)], k = L * 0.75;
  const P = (uu, v) => [cf[0] * L + ox + su[0] * uu + dx[0] * v, cf[1] * L + oy + su[1] * uu + dx[1] * v];
  x.lineWidth = Math.max(2, L / 4);
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
    x.font = `600 ${Math.round(Math.max(14, cv.width / 34))}px Oswald`;
    x.fillStyle = '#fff';
    x.strokeStyle = '#000';
    x.lineWidth = 4;
    const t = `${a.pilota.split(' ').slice(-1)[0]} ${['BB', 'B', 'M', 'A', 'MA'][a.quota]}`;
    x.strokeText(t, px - 30, py - k * 0.55);
    x.fillText(t, px - 30, py - k * 0.55);
  }
}

if (codice.length === 4 && nome && q.has('subito')) entra(); else accesso();
