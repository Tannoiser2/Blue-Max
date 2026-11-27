class_name Effetti
extends RefCounted
## Effetti particellari: fumo, fiamme, colpi di mitragliatrice, scintille, esplosioni, roghi a terra.

static func _mat(colore: Color, additivo := false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = colore
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	if additivo:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return m

static func _sfera(r: float, colore: Color, additivo := false) -> SphereMesh:
	var s = SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 8
	s.rings = 4
	s.material = _mat(colore, additivo)
	return s

static func _quad(r: float, colore: Color, additivo := false) -> QuadMesh:
	var q = QuadMesh.new()
	q.size = Vector2(r, r)
	q.material = _mat(colore, additivo)
	return q

static func _sfuma(a: Color, b: Color) -> Gradient:
	var g = Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	return g

static func scia_fumo(colore: Color) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 2.6
	p.local_coords = false
	p.mesh = _sfera(0.09, Color.WHITE)
	p.direction = Vector3(0, 0.3, -1)
	p.spread = 12
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.gravity = Vector3(0, 0.08, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var c = Curve.new()
	c.add_point(Vector2(0, 0.5))
	c.add_point(Vector2(1, 2.8))
	p.scale_amount_curve = c
	p.color_ramp = _sfuma(colore, Color(colore.r, colore.g, colore.b, 0.0))
	p.emitting = true
	return p

static func fiamme() -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.5
	p.local_coords = false
	p.mesh = _sfera(0.06, Color.WHITE, true)
	p.direction = Vector3(0, 0.6, -1)
	p.spread = 20
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3(0, 0.5, 0)
	p.color_ramp = _sfuma(Color(1.0, 0.75, 0.25, 0.95), Color(0.8, 0.15, 0.05, 0.0))
	p.emitting = true
	var l = OmniLight3D.new()
	l.light_color = Color(1, 0.55, 0.2)
	l.light_energy = 1.2
	l.omni_range = 1.6
	p.add_child(l)
	return p

static func lampo_bocca() -> Node3D:
	var n = Node3D.new()
	var l = OmniLight3D.new()
	l.light_color = Color(1, 0.85, 0.5)
	l.light_energy = 3.0
	l.omni_range = 2.2
	n.add_child(l)
	var p = CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.15
	p.mesh = _sfera(0.06, Color.WHITE, true)
	p.spread = 25
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.6
	p.gravity = Vector3.ZERO
	p.color_ramp = _sfuma(Color(1, 0.95, 0.6, 1), Color(1, 0.5, 0.1, 0))
	p.emitting = true
	n.add_child(p)
	return n

static func traccia() -> MeshInstance3D:
	var m = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = 0.028
	c.bottom_radius = 0.018
	c.height = 0.7
	c.radial_segments = 4
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.92, 0.55)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1, 0.75, 0.3)
	mat.emission_energy_multiplier = 3.0
	c.material = mat
	m.mesh = c
	m.rotation_degrees = Vector3(90, 0, 0)
	var rad = MeshInstance3D.new()
	rad.add_child(m)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return rad

static func scintille() -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.amount = 50
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 0.9
	p.mesh = _sfera(0.025, Color.WHITE, true)
	p.spread = 180
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 2.0
	p.gravity = Vector3(0, -2.5, 0)
	p.color_ramp = _sfuma(Color(1, 0.9, 0.5, 1), Color(0.6, 0.2, 0.05, 0))
	p.emitting = true
	# schegge di legno e tela
	var s = CPUParticles3D.new()
	s.amount = 16
	s.lifetime = 1.4
	s.one_shot = true
	s.explosiveness = 0.95
	var b = BoxMesh.new()
	b.size = Vector3(0.05, 0.01, 0.03)
	var mb = StandardMaterial3D.new()
	mb.albedo_color = Color("7a6545")
	b.material = mb
	s.mesh = b
	s.spread = 180
	s.initial_velocity_min = 0.4
	s.initial_velocity_max = 1.3
	s.angular_velocity_min = -400
	s.angular_velocity_max = 400
	s.gravity = Vector3(0, -2.0, 0)
	s.emitting = true
	p.add_child(s)
	return p

static func esplosione() -> Node3D:
	var n = Node3D.new()
	var fuoco = CPUParticles3D.new()
	fuoco.amount = 90
	fuoco.lifetime = 1.1
	fuoco.one_shot = true
	fuoco.explosiveness = 0.95
	fuoco.mesh = _sfera(0.16, Color.WHITE, true)
	fuoco.spread = 180
	fuoco.initial_velocity_min = 0.5
	fuoco.initial_velocity_max = 1.8
	fuoco.gravity = Vector3(0, 0.6, 0)
	var c = Curve.new()
	c.add_point(Vector2(0, 0.6))
	c.add_point(Vector2(1, 1.8))
	fuoco.scale_amount_curve = c
	var g = Gradient.new()
	g.set_color(0, Color(1, 0.95, 0.7, 1))
	g.set_color(1, Color(0.25, 0.1, 0.05, 0))
	g.add_point(0.35, Color(1, 0.5, 0.1, 0.9))
	fuoco.color_ramp = g
	fuoco.emitting = true
	n.add_child(fuoco)
	var fumo = CPUParticles3D.new()
	fumo.amount = 50
	fumo.lifetime = 3.0
	fumo.one_shot = true
	fumo.explosiveness = 0.7
	fumo.mesh = _sfera(0.22, Color.WHITE)
	fumo.spread = 180
	fumo.initial_velocity_min = 0.2
	fumo.initial_velocity_max = 0.8
	fumo.gravity = Vector3(0, 0.25, 0)
	fumo.color_ramp = _sfuma(Color(0.15, 0.13, 0.12, 0.85), Color(0.3, 0.3, 0.3, 0))
	fumo.emitting = true
	n.add_child(fumo)
	var l = OmniLight3D.new()
	l.light_color = Color(1, 0.6, 0.25)
	l.light_energy = 4.0
	l.omni_range = 4.0
	n.add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, 1.2)
	var sch = scintille()
	n.add_child(sch)
	return n

static func rogo() -> Node3D:
	var n = Node3D.new()
	var f = fiamme()
	f.amount = 30
	f.lifetime = 0.9
	f.direction = Vector3(0, 1, 0)
	n.add_child(f)
	var s = scia_fumo(Color(0.1, 0.1, 0.1, 0.7))
	s.direction = Vector3(0, 1, 0)
	s.initial_velocity_min = 0.2
	s.initial_velocity_max = 0.4
	s.gravity = Vector3(0.1, 0.3, 0)
	n.add_child(s)
	return n
