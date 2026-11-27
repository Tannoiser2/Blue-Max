class_name Hex
extends RefCounted
## Geometria degli esagoni (punta in alto, coordinate assiali q,r).
## Direzioni: 0 E, 1 SE, 2 SO, 3 O, 4 NO, 5 NE (sullo schermo, y verso il basso).

const DIR := [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]
const S3 := 1.7320508

static func vicino(c: Vector2i, d: int) -> Vector2i:
	return c + DIR[posmod(d, 6)]

static func distanza(a: Vector2i, b: Vector2i) -> int:
	var dq = a.x - b.x
	var dr = a.y - b.y
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2

## Centro dell'esagono in unità di lato (come nella foto raddrizzata, senza origine)
static func centro(c: Vector2i) -> Vector2:
	return Vector2(S3 * (c.x + c.y * 0.5), 1.5 * c.y)

## Angolo (gradi) della direzione d sullo schermo
static func angolo(d: int) -> float:
	return posmod(d, 6) * 60.0

## Differenza angolare (0..180) fra la prua d e il vettore da a verso b
static func scarto(a: Vector2i, d: int, b: Vector2i) -> float:
	var v = centro(b) - centro(a)
	if v.length() < 0.001:
		return 0.0
	var ang = rad_to_deg(atan2(v.y, v.x))
	var diff = fposmod(ang - angolo(d) + 180.0, 360.0) - 180.0
	return absf(diff)

## L'esagono b è nell'arco frontale (120°) dell'aereo in a con prua d, entro la distanza massima
static func in_arco_frontale(a: Vector2i, d: int, b: Vector2i, maxd := 3) -> bool:
	var n = distanza(a, b)
	if n == 0 or n > maxd:
		return false
	return scarto(a, d, b) <= 60.5

static func in_arco_posteriore(a: Vector2i, d: int, b: Vector2i, maxd := 3) -> bool:
	return in_arco_frontale(a, d + 3, b, maxd)

## Esagoni della linea di tiro davanti al muso (1..n)
static func linea(a: Vector2i, d: int, n: int) -> Array:
	var out = []
	var c = a
	for i in n:
		c = vicino(c, d)
		out.append(c)
	return out

## Distanza lungo la linea dritta davanti (0 se non è sulla linea)
static func su_linea(a: Vector2i, d: int, b: Vector2i, n := 4) -> int:
	var c = a
	for i in n:
		c = vicino(c, d)
		if c == b:
			return i + 1
	return 0
