#!/usr/bin/env python3
"""Genera i dati del gioco (data/*.json) dalle trascrizioni del regolamento e delle Schede-Movimento.
Fonte: regolamento italiano Stratelibri 1993 e Tabelle-Movimento Aereo scansionate da Stefano."""
import json, os
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data')

# Geometria delle manovre (versione Sinistra; la Destra è speculare). Passi relativi alla prua iniziale:
# 0 avanti, -1 avanti-sinistra, +1 avanti-destra, -2 dietro-sinistra, +2 dietro-destra, 3 dietro.
# "prua": rotazione finale (in sestanti) rispetto alla prua iniziale.
GEO = {
  1: ([], -1), 2: ([0], 0), 3: ([0, 0], 0), 4: ([0, 0, 0], 0), 5: ([0, 0, 0, 0], 0),
  6: ([0], -1), 7: ([0], 1), 8: ([-1], -1), 9: ([-1], -2), 10: ([-1], 0), 11: ([-1], 3),
  12: ([0, 0], -1), 13: ([0, 0], 1), 14: ([0, -1], -1), 15: ([0, -1], -2), 16: ([-1, -1], -1), 17: ([-1, -1], 0),
  18: ([0, 0, 0], -1), 19: ([0, 0, 0], 1), 20: ([0, 0, -1], -1), 21: ([0, -1, -1], -1), 22: ([0, -1, -1], -2),
  23: ([0, -1, -2], -2), 24: ([0, -1, -2], 3), 25: ([0, 0, 0, 0], -1), 26: ([0, 0, 0, 0], 1),
  27: ([], 3), 28: ([], -2), 29: ([0], 3), 30: ([0], -2), 31: ([-1], 1),
  32: ([0, 0], -2), 33: ([0, 0], 2), 34: ([0, -1], 0), 35: ([0, 1], 0), 36: ([-1, 0], 1),
}
NOMI = {
  0: 'Avvitamento (vite)', 1: 'Stallo / rotazione sul posto', 2: 'Avanti 1', 3: 'Avanti 2', 4: 'Avanti 3', 5: 'Avanti 4',
  6: 'Virata dolce a sinistra', 7: 'Virata dolce a destra', 8: 'Scivolata d\'ala', 9: 'Virata stretta', 10: 'Spostamento laterale',
  11: 'Rovesciamento d\'ala', 12: 'Virata larga 2', 13: 'Virata larga 2', 14: 'Virata 2', 15: 'Virata stretta 2',
  16: 'Scivolata d\'ala 2', 17: 'Spostamento laterale 2', 18: 'Virata larga 3', 19: 'Virata larga 3', 20: 'Virata 3',
  21: 'Virata ampia 3', 22: 'Virata stretta 3', 23: 'Virata strettissima 3', 24: 'Inversione 3', 25: 'Virata larga 4',
  26: 'Virata larga 4', 27: 'Inversione sul posto', 28: 'Rovesciamento sul posto', 29: 'Immelmann', 30: 'Immelmann virato',
  31: 'Foglia morta', 32: 'Cabrata rovesciata', 33: 'Cabrata rovesciata', 34: 'Tonneau', 35: 'Tonneau', 36: 'Vite controllata',
}
manovre = {}
for n, (passi, prua) in GEO.items():
    manovre[str(n)] = {'passi': passi, 'prua': prua, 'nome': NOMI[n],
                      'acrobatica': n >= 27, 'non_ripetibile': n in (1, 28, 31, 36)}
manovre['0'] = {'passi': [], 'prua': 0, 'nome': NOMI[0], 'acrobatica': False, 'non_ripetibile': False}

def sp(s):
    return s.split()
SET_ALB3 = sp('1S1 1A1 1D1 8S2 9S2 10S2 6A2 2A2 7A2 8D2 9D2 10D2 14S3 16S3 12A3 3A3 13A3 14D3 16D3 28S2 27A2 28D2 31S2 31D2 34A3 35A3')
SET_DR1 = sp('1S1 1A1 1D1 8S2 9S1 10S2 11S1 6A2 2A2 7A2 8D2 9D1 10D2 11D1 14S3 15S3 16S3 3A3 14D3 15D3 16D3 28S2 27A2 28D2 31S2 31D2 34A3 35A3')
SET_ALB5 = sp('1S1 1A1 1D1 8S1 10S1 6A1 2A1 7A1 8D1 10D1 14S2 16S2 17S2 12A2 3A2 13A2 14D2 16D2 17D2 '
              '20S3 21S3 22S3 18A3 4A3 19A3 20D3 21D3 22D3 30S2 30D2 29A2 31S2 31D2 32A3 33A3 34A3 35A3')
SET_SPAD7 = sp('1A1 8S1 10S1 6A1 2A1 7A1 8D1 10D1 14S2 16S2 17S2 12A2 3A2 13A2 14D2 16D2 17D2 '
               '20S3 21S3 22S3 18A3 4A3 19A3 20D3 21D3 22D3 30S2 30D2 29A2 32A3 33A3 34A3 35A3 36S3 36D3')
SET_SNIPE = sp('1S1 1A1 1D1 8S1 9S2 10S1 11S2 6A1 2A1 7A1 8D1 9D2 10D1 11D2 14S2 15S2 16S2 17S2 12A2 3A2 13A2 14D2 15D2 16D2 17D2 '
               '20S3 21S3 22S3 23S3 24S3 18A3 4A3 19A3 20D3 21D3 22D3 23D3 24D3 30S2 30D2 29A2 31S2 31D2 32A3 33A3 34A3 35A3 36S3 36D3')
SET_D7 = sp('1S1 1A1 1D1 8S1 10S1 6A1 2A1 7A1 8D1 10D1 14S2 15S2 16S2 17S2 12A2 3A2 13A2 14D2 15D2 16D2 17D2 '
            '20S3 21S3 22S3 23S3 24S3 18A3 4A3 19A3 20D3 21D3 22D3 23D3 24D3 30S2 30D2 29A2 31S2 31D2 32A3 33A3 34A3 35A3 36S3 36D3')
aerei = [
 # id, nome, nazioni, stabilita, motore, ali, fusoliera, coda, carburante, armamento, quota max, manovre, modello, provvisorio
 ('albatros_d3', 'Albatros D.III', ['germania'], 'B', 8, 22, 24, 6, 45, '2M', 'A', SET_ALB3),
 ('albatros_d5', 'Albatros D.Va', ['germania'], 'B', 8, 22, 24, 6, 45, '2M', 'A', SET_ALB5),
 ('halberstadt', 'Halberstadt CL.IIa', ['germania'], 'B', 8, 28, 23, 5, 67, '1M,1O', 'A',
  sp('1S1 1A1 1D1 8S2 9S1 10S2 6A1 2A1 7A1 8D2 9D1 10D2 14S3 15S3 16S3 3A3 14D3 15D3 16D3 28S2 27A2 28D2 31S2 31D2')),
 ('fokker_dr1', 'Fokker Dr.I', ['germania'], 'C', 6, 18, 19, 5, 37, '2M', 'A+', SET_DR1),
 ('pfalz_d3', 'Pfalz D.IIIa', ['germania'], 'B', 8, 23, 27, 5, 45, '2M', 'A', SET_DR1),
 ('fokker_d7', 'Fokker D.VII', ['germania'], 'A', 8, 22, 22, 5, 37, '2M', 'A+', SET_D7),
 ('pfalz_d12', 'Pfalz D.XII', ['germania'], 'B', 8, 23, 20, 5, 55, '2M', 'A', SET_SPAD7),
 ('ssw_d3', 'Siemens-Schuckert D.III', ['germania'], 'A', 6, 20, 18, 5, 45, '2M', 'MA+', SET_SNIPE),
 ('ssw_d4', 'Siemens-Schuckert D.IV', ['germania'], 'A', 6, 20, 18, 5, 45, '2M', 'MA+', SET_SNIPE),
 ('nieuport17', 'Nieuport 17', ['inghilterra', 'francia'], 'B', 6, 13, 20, 4, 45, '1M', 'A',
  sp('1S1 1A1 1D1 8S2 9S1 10S2 6A2 2A2 7A2 8D2 9D1 10D2 14S3 15S3 16S3 3A3 14D3 15D3 16D3 28S2 27A2 28D2 31S2 31D2 34A3 35A3')),
 ('spad7', 'Spad VII', ['inghilterra', 'francia'], 'B', 8, 22, 20, 5, 52, '1M', 'A', SET_SPAD7),
 ('triplane', 'Sopwith Triplane', ['inghilterra'], 'A', 6, 23, 18, 4, 52, '1M', 'MA', SET_DR1),
 ('bristol', 'Bristol F.2B', ['inghilterra'], 'A', 8, 40, 28, 6, 67, '1M,2O,L', 'MA',
  sp('1S1 1A1 1D1 8S2 9S2 10S2 6A2 2A2 7A2 8D2 9D2 10D2 14S3 16S3 12A3 3A3 13A3 14D3 16D3 27A2 31S2 31D2')),
 # S.E.5a: manovre dal foglio AMS revisionato (cartella ADD), che manca fra le Tabelle-Movimento italiane
 ('se5a', 'S.E.5a', ['inghilterra'], 'A', 8, 24, 21, 5, 52, '1M,1ML', 'MA',
  sp('1A1 8S1 10S1 6A1 2A1 7A1 8D1 10D1 14S2 16S2 17S2 12A2 3A2 13A2 14D2 16D2 17D2 '
     '20S3 21S3 22S3 23S3 18A3 4A3 19A3 20D3 21D3 22D3 23D3 30S2 30D2 29A2 31S2 31D2 32A3 33A3 34A3 35A3 36S3 36D3')),
 ('camel', 'Sopwith Camel', ['inghilterra'], 'C', 6, 24, 18, 4, 55, '2M', 'A',
  # Camel: Tabella-Movimento corretta GDW (cartella ADD), con la 16D3 che mancava
  sp('1S1 1A1 1D1 8S2 10S2 6A2 2A2 7A2 8D1 9D1 10D2 11D1 14S3 16S3 3A3 14D3 15D3 16D3 28S2 27A2 28D2 31S2 31D2 34A3 35A3')),
 ('spad13', 'Spad XIII', ['francia', 'usa'], 'B', 8, 24, 20, 6, 52, '2M', 'MA',
  SET_SPAD7[:-2] + sp('25A4 5A4 26A4 36S3 36D3')),
 ('nieuport28', 'Nieuport 28', ['usa'], 'B', 6, 22, 20, 5, 45, '2M', 'A', SET_ALB5),
 ('snipe', 'Sopwith Snipe', ['inghilterra'], 'A', 6, 27, 19, 5, 67, '2M', 'A', SET_SNIPE),
]
# Il Sopwith Triplane usa la stessa Tabella-Movimento del Fokker Dr.I (foglio AMS «Fokker Dr.1 / Sopwith Triplane»)
PROVVISORI = {}
# Disponibilita storica (mese 0 = gennaio 1917)
DISP = {'albatros_d3': -3, 'nieuport17': -8, 'spad7': -4, 'triplane': 1, 'bristol': 3, 'se5a': 5, 'albatros_d5': 5,
        'halberstadt': 6, 'camel': 7, 'spad13': 7, 'fokker_dr1': 7, 'pfalz_d3': 7, 'nieuport28': 15, 'fokker_d7': 15,
        'ssw_d3': 15, 'ssw_d4': 19, 'snipe': 20, 'pfalz_d12': 20}
QUOTE = {'BB': 0, 'B': 1, 'M': 2, 'A': 3, 'MA': 4}
MODELLI = {'snipe': 'camel', 'pfalz_d12': 'pfalz_d3', 'ssw_d4': 'ssw_d3'}
# Aerei aggiuntivi dai fogli AMS revisionati delle Blue Max Miniature Rules (cartella ADD/BMMRP):
# manovre e caratteristiche dai fogli; il carburante non c'è e si usa quello di aerei simili.
CAMEL = [x for x in aerei if x[0] == 'camel'][0][11]
for x in json.load(open(os.path.join(R, 'aggiuntivi_src.json'), encoding='utf-8')):
    man = x['manovre'] if x['manovre'] else CAMEL
    aerei.append((x['id'], x['nome'], x['nazioni'], x['st'], x['mot'], x['ali'], x['fus'], x['coda'], x['carb'], x['arm'], x['q'], man))
    DISP[x['id']] = x['disp']
    MODELLI[x['id']] = x['modello']
AGGIUNTIVI = set(json.load(open(os.path.join(R, 'aggiuntivi_src.json'), encoding='utf-8'))[i]['id'] for i in range(len(json.load(open(os.path.join(R, 'aggiuntivi_src.json'), encoding='utf-8')))))
out = []
for (i, n, naz, st, mot, ali, fus, coda, carb, arm, q, man) in aerei:
    quota = QUOTE[q.rstrip('+')]
    armi = arm.split(',')
    pilota_m = 0; oss = 0; lewis_pilota = 0; lewis_oss = False
    for a in armi:
        if a.endswith('M') and a != '1ML': pilota_m += int(a[0])
        if a == '1ML': pilota_m += 1; lewis_pilota = 1
        if a.endswith('O'): oss = int(a[0])
        if a == 'L': lewis_oss = True
    out.append({'id': i, 'nome': n, 'nazioni': naz, 'stabilita': st, 'motore': mot, 'ali': ali, 'fusoliera': fus,
                'coda': coda, 'carburante': carb, 'armamento': arm, 'mitragliatrici': pilota_m,
                'lewis_pilota': lewis_pilota, 'osservatore': oss, 'lewis_osservatore': lewis_oss,
                'caricatori_lewis': 8 if i == 'bristol' else 4,
                'quota_max': quota, 'quota_piu': q.endswith('+'), 'manovre': man,
                'velocita_max': max(int(c[-1]) for c in man), 'disponibile_dal': DISP[i],
                'provvisorio': PROVVISORI.get(i, ''), 'modello': MODELLI.get(i, i),
                'aggiuntivo': i in AGGIUNTIVI})

# Pedine-danno: 36 rosse e 36 blu (trascritte dalle foto). Tipi: ala, fusoliera, coda, motore + effetti speciali.
def D(**k): return k
ROSSE = [D(coda=4), D(ala=8), D(spec='serbatoio', carb=6, fusoliera=3), D(fusoliera=7), D(spec='esplosione'), D(fusoliera=8),
 D(spec='timone', dir='D', turni=3, coda=1), D(spec='timone', dir='D', turni=2, coda=1), D(fusoliera=7), D(ala=6), D(fusoliera=6),
 D(spec='oss_ucciso', fusoliera=4), D(motore=3), D(fusoliera=5), D(ala=5), D(fusoliera=8), D(ala=6), D(spec='oss_ucciso', fusoliera=4),
 D(motore=4), D(motore=4), D(spec='pilota_ucciso'), D(spec='pilota_ucciso'), D(spec='serbatoio', carb=3, fusoliera=2), D(ala=5),
 D(spec='timone', dir='S', turni=2, coda=1), D(fusoliera=6), D(coda=3), D(coda=4), D(fusoliera=5), D(coda=3), D(ala=8), D(spec='fuoco'),
 D(motore=3), D(ala=7), D(spec='timone', dir='S', turni=3, coda=1), D(ala=7)]
BLU = [D(coda=2), D(ala=4), D(spec='fumo'), D(fusoliera=3), D(spec='ferito_avanti', fusoliera=1), D(fusoliera=4),
 D(spec='ala_lacerata_veloce', ala=3), D(spec='montante', ala=1), D(fusoliera=3), D(ala=2), D(fusoliera=2),
 D(spec='oss_ferito', turni=3, fusoliera=3), D(motore=1), D(fusoliera=1), D(ala=1), D(fusoliera=4), D(ala=2),
 D(spec='oss_ucciso', fusoliera=3), D(motore=2), D(motore=2), D(spec='pilota_ucciso'), D(spec='ferito_lento', fusoliera=1),
 D(spec='motore_colpito', fusoliera=1, motore=2), D(ala=1), D(spec='mitragliatrice', fusoliera=3), D(fusoliera=2), D(coda=1),
 D(coda=2), D(fusoliera=1), D(coda=1), D(ala=4), D(spec='fumo'), D(motore=1), D(ala=3), D(spec='ala_lacerata', ala=4), D(ala=3)]
assert len(ROSSE) == 36 and len(BLU) == 36
TESTI = {
 'serbatoio': 'Serbatoio colpito', 'esplosione': 'Serbatoio colpito - ESPLOSIONE!', 'timone': 'Timone inceppato',
 'oss_ucciso': 'Osservatore ucciso', 'oss_ferito': 'Osservatore ferito', 'pilota_ucciso': 'Pilota ucciso', 'fuoco': 'Fuoco',
 'fumo': 'Fumo', 'ferito_avanti': 'Pilota ferito', 'ferito_lento': 'Pilota ferito', 'ala_lacerata': 'Ala lacerata',
 'ala_lacerata_veloce': 'Ala lacerata', 'montante': 'Montante distrutto', 'motore_colpito': 'Motore colpito',
 'mitragliatrice': '1 mitragliatrice distrutta'}

COMBATTIMENTO = {
  'distanze': [3, 2, 1, 0], 'base': [2, 3, 5, 7],
  'mod': {
    'corta': [0, 0, 0, 0], 'media': [1, 1, 2, 2], 'lunga': [2, 2, 3, 4],
    'stab_A': [1, 1, 2, 3], 'stab_B': [0, 0, 1, 2], 'stab_C': [-1, 0, 0, 1],
    'stallo': [2, 2, 3, 0], 'veloce': [-3, -2, -1, 0], 'singola': [-3, -2, -2, -2],
    'angolata': [-3, -2, -1, 0], 'inquadrato': [0, 1, 1, 2], 'tallonato': [1, 1, 2, 2], 'inferiore': [0, 1, 1, 1]},
  # risultati[dado-1][valore-1]: [blu, rosse]
  'risultati': [
    ['-', '-', '-', 'B', 'B', 'B', 'B', '2B', 'R', 'BR', 'BR', '2R', '3R', 'B3R', '4R'],
    ['-', '-', 'B', 'B', 'B', 'B', '2B', 'R', 'BR', 'BR', '2R', '3R', 'B3R', '4R', '5R'],
    ['-', 'B', 'B', 'B', 'B', '2B', 'R', 'R', 'BR', '2R', '3R', 'B3R', '4R', '5R', '6R'],
    ['B', 'B', 'B', 'B', '2B', 'R', 'R', 'BR', '2R', '3R', 'B3R', '4R', '5R', '6R', '7R'],
    ['B', 'B', 'B', '2B', 'R', 'R', 'BR', '2R', '3R', 'B3R', '4R', '5R', '6R', '7R', '8R'],
    ['B', 'B', '2B', 'R', 'R', '2R', '2R', '3R', 'B3R', '4R', '5R', '6R', '7R', '8R', '9R']],
}
def parse(c):
    if c == '-': return [0, 0]
    b = r = 0; n = ''
    for ch in c:
        if ch.isdigit(): n += ch
        else:
            k = int(n) if n else 1; n = ''
            if ch == 'B': b += k
            else: r += k
    return [b, r]
COMBATTIMENTO['risultati'] = [[parse(c) for c in riga] for riga in COMBATTIMENTO['risultati']]

json.dump({'manovre': manovre}, open(f'{R}/manovre.json', 'w'), ensure_ascii=False, indent=1)
json.dump({'aerei': out}, open(f'{R}/aerei.json', 'w'), ensure_ascii=False, indent=1)
json.dump({'rosse': ROSSE, 'blu': BLU, 'testi': TESTI}, open(f'{R}/danni.json', 'w'), ensure_ascii=False, indent=1)
json.dump(COMBATTIMENTO, open(f'{R}/combattimento.json', 'w'), ensure_ascii=False, indent=1)
print('ok', len(out), 'aerei')
