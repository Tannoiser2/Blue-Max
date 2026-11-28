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
      h += `<div class="man g${GRUPPI.indexOf(g)} ${ok ? '' : 'no'} ${scelta.codice === c ? 'sel' : ''}" data-c="${c}" data-gr="${GRUPPI.indexOf(g)}" data-d="${k.dir}"><canvas data-g="${c}"></canvas><span>${NONRIP.includes(k.n) ? '(' + c + ')' : c}</span></div>`;
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
// tre colonne fisse, S a sinistra, A al centro, D a destra, una fascia per gruppo di velocità;
// si cerca la cella più grande che fa stare tutto nella scheda senza scorrere
function impagina() {
  const gr = document.getElementById('griglia');
  if (!gr) return;
  const celle = [...gr.querySelectorAll('.man')];
  gr.querySelectorAll('.zona').forEach((z) => z.remove());
  const W = gr.clientWidth, TESTA = 18, H = gr.clientHeight - TESTA, gap = 3, sep = 8;
  const gruppi = [...new Set(celle.map((c) => +c.dataset.gr))];
  const conta = {};
  for (const c of celle) { const k = c.dataset.gr + c.dataset.d; conta[k] = (conta[k] || 0) + 1; }
  const n = (g, d) => conta[g + d] || 0;
  const mass = ['S', 'A', 'D'].map((d) => Math.max(1, ...gruppi.map((g) => n(g, d))));
  let best = null;
  for (let w = 120; w >= 26; w -= 2) {
    const h = Math.round(w * 1.15);
    const tot = Math.floor((W - 2 * sep + 3 * gap) / (w + gap));
    if (tot < 3) continue;
    let migl = null;
    for (let cs = 1; cs <= Math.min(tot - 2, mass[0]); cs++) {
      for (let ca = 1; ca <= Math.min(tot - cs - 1, mass[1]); ca++) {
        const cd = Math.min(tot - cs - ca, mass[2]);
        if (cd < 1) continue;
        const righe = gruppi.reduce((t, g) => t + Math.max(1, Math.ceil(n(g, 'S') / cs), Math.ceil(n(g, 'A') / ca), Math.ceil(n(g, 'D') / cd)), 0);
        if (!migl || righe < migl[0]) migl = [righe, [cs, ca, cd]];
      }
    }
    if (migl && migl[0] * (h + gap) + (gruppi.length - 1) * 4 <= H) { best = [w, h, migl[1]]; break; }
  }
  if (!best) best = [26, 30, [1, 1, 1]];
  const [w, h, col] = best;
  const usato = (col[0] + col[1] + col[2]) * (w + gap) - 3 * gap + 2 * sep;
  let x = Math.max(0, (W - usato) / 2);
  const zone = [];
  for (let k = 0; k < 3; k++) { const x1 = x + col[k] * (w + gap) - gap; zone.push([x, x1]); x = x1 + gap + sep; }
  ['Sinistra (S)', 'Avanti (A)', 'Destra (D)'].forEach((t, k) => {
    const z = document.createElement('div');
    z.className = 'zona' + (k === 1 ? '' : ' laterale');
    z.style.left = (zone[k][0] - 2) + 'px'; z.style.width = (zone[k][1] - zone[k][0] + 4) + 'px';
    z.textContent = t;
    gr.prepend(z);
  });
  const dpr = Math.min(2, window.devicePixelRatio || 1);
  const fs = Math.max(10, Math.min(16, Math.floor(h * 0.16)));
  let y = TESTA;
  for (const g of gruppi) {
    let righe = 1;
    ['S', 'A', 'D'].forEach((d, k) => {
      const lista = celle.filter((c) => +c.dataset.gr === g && c.dataset.d === d);
      righe = Math.max(righe, Math.ceil(lista.length / col[k]));
      lista.forEach((el, i) => {
        const ic = i % col[k], ir = Math.floor(i / col[k]);
        let cx;
        if (k === 0) cx = zone[0][1] - w - ic * (w + gap);
        else if (k === 2) cx = zone[2][0] + ic * (w + gap);
        else { const nr = Math.min(lista.length - ir * col[k], col[k]); cx = (zone[1][0] + zone[1][1]) / 2 - (nr * (w + gap) - gap) / 2 + ic * (w + gap); }
        Object.assign(el.style, { left: cx + 'px', top: (y + ir * (h + gap)) + 'px', width: w + 'px', height: h + 'px' });
        el.querySelector('span').style.fontSize = fs + 'px';
        const cv = el.querySelector('canvas');
        const cw = w - 4, ch = Math.max(10, h - fs - 8);
        cv.style.width = cw + 'px'; cv.style.height = ch + 'px';
        cv.width = Math.round(cw * dpr); cv.height = Math.round(ch * dpr);
        disegnaManovra(cv);
      });
    });
    y += righe * (h + gap) + 4;
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
// mappa ruotata: il muso del mio aereo punta sempre in alto, con la linea di tiro davanti
function disegnaMappa() {
  const cv = document.getElementById('mappa');
  if (!cv || !stato) return;
  const x = cv.getContext('2d');
  const W = 18.95, H = 23.3, O = [-2.75, -1.8];
  const vivi = stato.aerei.filter((a) => ['volo', 'vite', 'planata'].includes(a.stato));
  const cen = (q, r) => [S3 * (q + r * 0.5) - O[0], 1.5 * r - O[1]];
  const io = mio && vivi.find((a) => a.id === mio.id);
  let c0, rot;
  if (io) {
    c0 = cen(io.q, io.r);
    rot = -(io.prua * Math.PI) / 3 - Math.PI / 2;
  } else {
    c0 = [W / 2, H / 2];
    rot = 0;
  }
  // raggio da mostrare: tutti gli aerei vicini, almeno 4 esagoni
  let rag = 4.5;
  for (const a of vivi) { const [cx, cy] = cen(a.q, a.r); rag = Math.max(rag, Math.hypot(cx - c0[0], cy - c0[1]) + 1.6); }
  rag = Math.min(rag, 12);
  const k = Math.min(cv.width, cv.height) / (2 * rag);
  // il mio aereo un po' sotto il centro: si vede di più quello che ha davanti
  const ox = cv.width / 2, oy = cv.height * (io ? 0.62 : 0.5);
  const schermo = (wx, wy) => {
    const dx = wx - c0[0], dy = wy - c0[1];
    return [ox + k * (dx * Math.cos(rot) - dy * Math.sin(rot)), oy + k * (dx * Math.sin(rot) + dy * Math.cos(rot))];
  };
  x.setTransform(1, 0, 0, 1, 0, 0);
  x.fillStyle = '#3b2f22';
  x.fillRect(0, 0, cv.width, cv.height);
  x.save();
  x.translate(ox, oy); x.rotate(rot); x.scale(k, k); x.translate(-c0[0], -c0[1]);
  if (mappaImg.complete && mappaImg.naturalWidth) x.drawImage(mappaImg, 0, 0, W, H);
  // linea di tiro: 3 esagoni dritti davanti al muso
  if (io) {
    const D = [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]][io.prua];
    x.fillStyle = 'rgba(200,40,30,0.28)';
    x.strokeStyle = 'rgba(200,40,30,0.9)';
    x.lineWidth = 0.07;
    for (let n = 1; n <= 3; n++) {
      const [hx, hy] = cen(io.q + D[0] * n, io.r + D[1] * n);
      x.beginPath();
      for (let v = 0; v < 6; v++) { const t = Math.PI / 6 + (v * Math.PI) / 3; x.lineTo(hx + Math.cos(t) * 0.95, hy + Math.sin(t) * 0.95); }
      x.closePath(); x.fill(); x.stroke();
    }
  }
  x.restore();
  for (const a of vivi) {
    const [cx, cy] = cen(a.q, a.r);
    const [px, py] = schermo(cx, cy);
    const col = a.lato === 'G' ? '#b8322a' : '#2e6aa8';
    x.save();
    x.translate(px, py);
    x.rotate((a.prua * Math.PI) / 3 + rot);
    x.fillStyle = col;
    x.strokeStyle = io && a.id === io.id ? '#c9a23c' : '#fff';
    x.lineWidth = 3;
    x.beginPath(); x.moveTo(k * 0.55, 0); x.lineTo(-k * 0.4, -k * 0.35); x.lineTo(-k * 0.25, 0); x.lineTo(-k * 0.4, k * 0.35); x.closePath();
    x.fill(); x.stroke();
    x.restore();
    x.font = `600 ${Math.round(Math.max(14, cv.width / 30))}px Oswald`;
    x.fillStyle = '#fff';
    x.strokeStyle = '#000';
    x.lineWidth = 4;
    x.textAlign = 'center';
    const t = `${a.pilota.split(' ').slice(-1)[0]} ${['BB', 'B', 'M', 'A', 'MA'][a.quota]}`;
    x.strokeText(t, px, py - k * 0.6);
    x.fillText(t, px, py - k * 0.6);
  }
  if (io) {
    x.font = `600 ${Math.round(Math.max(13, cv.width / 34))}px Oswald`;
    x.textAlign = 'left';
    x.fillStyle = '#f3ead6'; x.strokeStyle = '#000'; x.lineWidth = 4;
    const nota = 'Il tuo muso punta in alto. In rosso la linea di tiro.';
    x.strokeText(nota, 10, cv.height - 12); x.fillText(nota, 10, cv.height - 12);
  }
}

if (codice.length === 4 && nome && q.has('subito')) entra(); else accesso();
