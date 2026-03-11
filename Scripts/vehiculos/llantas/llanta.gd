extends RayCast3D
class_name Llanta

# ════════════════════════════════════════════════════════════════════
# NUEVA FÍSICA DE SUSPENSIÓN Y NEUMÁTICOS - Sistema Completo V2
# ════════════════════════════════════════════════════════════════════

@export_group("Suspensión")
@export var largo_reposo: float = 0.28  # Reducido para bajar el vehículo
@export var radio_rueda: float = 0.55
@export var rigidez_muelle: float = 65000.0  # Más rígido para soportar peso
@export var amortiguacion: float = 9000.0  # Más amortiguación
@export var fuerza_suspension_max: float = 240000.0
@export var extra_largo_rayo: float = 0.18  # Reducido para menos recorrido

@export_group("Neumático")
@export var agarre_longitudinal: float = 2.8  # Mucho más agarre para acelerar
@export var agarre_lateral: float = 8.0  # EXTREMO agarre lateral para giros rápidos
@export var fuerza_max_freno: float = 15000.0
@export var respuesta_lateral: float = 350.0  # Respuesta ultra rápida en curvas
@export var usar_torque_asistencia_direccion: bool = false
@export var torque_asistencia_direccion: float = 15000.0

@export_group("Estabilidad")
@export var resistencia_rodadura: float = 180.0
@export var respuesta_lateral_reposo: float = 900.0
@export var respuesta_longitudinal_reposo: float = 700.0
@export var umbral_vel_reposo: float = 0.6
@export var fuerza_guiado_direccion: float = 2200.0

@export_group("Rol de rueda")
@export var es_tractriz: bool = true
@export var es_freno_mano: bool = false
@export var es_directriz: bool = false

@export_group("Anti-Dive/Squat")
@export var coeficiente_geometria: float = 0.3  # Geometría de suspensión

var coche: RigidBody3D
var rueda_visual: Node3D

# Estado de la rueda
var torque_drive: float = 0.0
var fuerza_freno: float = 0.0
var fuerza_freno_mano: float = 0.0
var angulo_direccion: float = 0.0

# Visual
var vel_rodado_visual: float = 0.0
var angulo_rodado_visual: float = 0.0
var rotacion_visual_base: Quaternion = Quaternion.IDENTITY

# Física avanzada
var compresion_anterior: float = 0.0
var velocidad_suspension: float = 0.0
var fuerza_normal_anterior: float = 0.0
var aceleracion_longitudinal_coche: float = 0.0

func _ready() -> void:
	coche = _buscar_coche(get_parent())
	if coche:
		add_exception(coche)
	
	if get_child_count() > 0:
		rueda_visual = get_child(0)
		rotacion_visual_base = rueda_visual.quaternion
	
	target_position = Vector3(0.0, -(largo_reposo + radio_rueda + extra_largo_rayo), 0.0)

func _physics_process(delta: float) -> void:
	if not coche or coche.freeze:
		return

	force_raycast_update()

	if is_colliding():
		_aplicar_fisica_contacto(delta)
	else:
		_aplicar_suspension_libre(delta)

	_actualizar_visual(delta)

# ════════════════════════════════════════════════════════════════════
# FÍSICA CON CONTACTO - NUEVO SISTEMA
# ════════════════════════════════════════════════════════════════════

func _aplicar_fisica_contacto(delta: float) -> void:
	var punto_contacto: Vector3 = get_collision_point()
	var centro_masa: Vector3 = coche.global_position + coche.global_transform.basis * coche.center_of_mass
	var radio_vec: Vector3 = punto_contacto - centro_masa

	# Direcciones locales del vehículo (ortonormalizadas para evitar ejes no unitarios)
	var basis_ortho: Basis = coche.global_transform.basis.orthonormalized()
	var up: Vector3 = basis_ortho.y.normalized()
	var right: Vector3 = basis_ortho.x.normalized()
	var forward: Vector3 = -basis_ortho.z.normalized()
	
	# Aplicar dirección de volante
	if es_directriz and abs(angulo_direccion) > 0.001:
		forward = forward.rotated(up, -angulo_direccion)
		right = right.rotated(up, -angulo_direccion)

	# Cálculo de compresión de suspensión
	var distancia_hasta_contacto: float = global_position.distance_to(punto_contacto)
	var recorrido_actual: float = max(distancia_hasta_contacto - radio_rueda, 0.0)
	var compresion: float = clamp(largo_reposo - recorrido_actual, 0.0, largo_reposo)
	
	# Velocidad de compresión/extensión
	velocidad_suspension = (compresion - compresion_anterior) / delta if delta > 0 else 0.0
	compresion_anterior = compresion

	# Velocidad del punto de contacto
	var vel_punto: Vector3 = coche.linear_velocity + coche.angular_velocity.cross(radio_vec)
	var vel_vertical: float = up.dot(vel_punto)

	# ════════════════════════════════════════════════════════════════
	# SUSPENSIÓN CON ANTI-DIVE/SQUAT REAL
	# ════════════════════════════════════════════════════════════════
	
	# Fuerza base de la suspensión (muelle + amortiguador)
	var fuerza_muelle: float = compresion * rigidez_muelle
	var fuerza_amortiguador: float = -vel_vertical * amortiguacion
	var fuerza_suspension_base: float = fuerza_muelle + fuerza_amortiguador
	
	# Calcular aceleración longitudinal del coche
	var inv_basis = coche.global_transform.basis.inverse()
	var vel_local = inv_basis * coche.linear_velocity
	var aceleracion_coche = (vel_local.z - aceleracion_longitudinal_coche) / delta if delta > 0 else 0.0
	aceleracion_longitudinal_coche = vel_local.z
	
	# Anti-dive/squat basado en geometría de suspensión
	var fuerza_anti_geometrica: float = 0.0
	
	if es_directriz:
		# DELANTERAS: Anti-dive al frenar, extensión al acelerar
		# Aceleración positiva (hacia adelante) = REDUCE la fuerza de suspensión (extensión)
		# Aceleración negativa (frenando) = AUMENTA la fuerza (compresión)
		fuerza_anti_geometrica = -aceleracion_coche * coche.mass * coeficiente_geometria
	else:
		# TRASERAS: Squat al acelerar, extensión al frenar
		# Aceleración positiva (hacia adelante) = AUMENTA la fuerza (compresión)
		# Aceleración negativa (frenando) = REDUCE la fuerza (extensión)
		fuerza_anti_geometrica = aceleracion_coche * coche.mass * coeficiente_geometria
	
	# Fuerza normal total con anti-dive/squat
	var fuerza_normal_total: float = fuerza_suspension_base + fuerza_anti_geometrica
	fuerza_normal_total = clamp(fuerza_normal_total, 0.0, fuerza_suspension_max)
	fuerza_normal_anterior = fuerza_normal_total
	
	# Aplicar fuerza normal vertical
	coche.apply_force(up * fuerza_normal_total, radio_vec)

	# ════════════════════════════════════════════════════════════════
	# FUERZAS LONGITUDINALES (Tracción/Frenado)
	# ════════════════════════════════════════════════════════════════
	
	var vel_forward: float = forward.dot(vel_punto)
	vel_rodado_visual = vel_forward

	# Lógica de marchas (P/R/N/D)
	var multiplicador_motor: float = 0.0
	var bloqueo_parking: bool = false
	if is_instance_valid(InputVehiculo):
		match InputVehiculo.marcha_actual:
			InputVehiculo.Marcha.PARQUEO:
				bloqueo_parking = true
				multiplicador_motor = 0.0
			InputVehiculo.Marcha.REVERSA:
				multiplicador_motor = 1.0
			InputVehiculo.Marcha.NEUTRO:
				multiplicador_motor = 0.0
			InputVehiculo.Marcha.DRIVE:
				multiplicador_motor = 1.0
	
	# Tracción
	var fuerza_traccion: float = 0.0
	if es_tractriz and not bloqueo_parking:
		var par_motor_final: float = torque_drive * multiplicador_motor
		var fuerza_teorica: float = 0.0
		if abs(par_motor_final) > 0.1:
			fuerza_teorica = par_motor_final / max(radio_rueda, 0.05)
		var limite_traccion: float = agarre_longitudinal * fuerza_normal_total
		fuerza_traccion = clamp(fuerza_teorica, -limite_traccion, limite_traccion)
		
		# DEBUG: Ver fuerzas de tracción aplicadas
		if Engine.get_frames_drawn() % 60 == 0:
			print("Rueda tractriz - Torque: %.0f, Fuerza: %.0f, Limite: %.0f" % [par_motor_final, fuerza_traccion, limite_traccion])
	
	# Frenado
	var fuerza_freno_total: float = fuerza_freno + fuerza_freno_mano
	if (bloqueo_parking and es_tractriz) or (fuerza_freno_mano > 0.0 and es_freno_mano):
		var fuerza_bloqueo: float = -vel_forward * (rigidez_muelle * 0.5)
		fuerza_traccion += clamp(fuerza_bloqueo, -15000.0, 15000.0)
	elif fuerza_freno_total > 0.01:
		var limite_freno: float = agarre_longitudinal * fuerza_normal_total * 1.5
		var signo_vel: float = sign(vel_forward)
		if abs(vel_forward) > 0.1:
			fuerza_traccion -= signo_vel * min(fuerza_freno_total, limite_freno)

	# Resistencia de rodadura para evitar sensación de hielo al soltar pedales.
	if abs(vel_forward) > 0.02:
		var fuerza_rodadura: float = -sign(vel_forward) * min(abs(vel_forward) * resistencia_rodadura, agarre_longitudinal * fuerza_normal_total)
		fuerza_traccion += fuerza_rodadura

	# Bloqueo estático en baja velocidad cuando no hay entrada.
	var sin_entrada_longitudinal: bool = abs(torque_drive) < 0.1 and fuerza_freno_total < 0.05
	if sin_entrada_longitudinal and abs(vel_forward) < umbral_vel_reposo:
		var fuerza_reposo_long: float = clamp(
			-vel_forward * respuesta_longitudinal_reposo,
			-agarre_longitudinal * fuerza_normal_total,
			agarre_longitudinal * fuerza_normal_total
		)
		fuerza_traccion += fuerza_reposo_long
	
	coche.apply_force(forward * fuerza_traccion, radio_vec)

	# ════════════════════════════════════════════════════════════════
	# FUERZAS LATERALES (El secreto para que no derrape)
	# ════════════════════════════════════════════════════════════════

	# 1. Calculamos la velocidad lateral relativa a donde apunta la LLANTA
	var vel_lateral: float = right.dot(vel_punto)

	# 2. Amortiguación lateral: Esta fuerza OPONE al movimiento lateral
	# Si la rueda se desliza a la derecha, aplicamos fuerza a la izquierda.
	var atenuacion_baja_vel: float = clamp(abs(vel_forward) * 2.0, 0.1, 1.0)
	var fuerza_lateral: float = -vel_lateral * respuesta_lateral * (fuerza_normal_total / 1000.0) * atenuacion_baja_vel

	# 3. Limitamos por el Círculo de Fricción (No puede haber más agarre que carga normal)
	var limite_lateral: float = fuerza_normal_total * agarre_lateral
	fuerza_lateral = clamp(fuerza_lateral, -limite_lateral, limite_lateral)
	
	# DEBUG: Ver fuerzas laterales en ruedas directrices
	if es_directriz and abs(fuerza_lateral) > 100.0 and Engine.get_frames_drawn() % 60 == 0:
		print("Rueda directriz - Ángulo: %.2f°, Fuerza lateral: %.0f N" % [rad_to_deg(angulo_direccion), fuerza_lateral])
	
	coche.apply_force(right * fuerza_lateral, radio_vec)
	
	# Opcional: asistencia de torque (apagada por defecto).
	# Si se activa, añade yaw directo al rigidbody y puede sentirse como giro desde el centro.
	if usar_torque_asistencia_direccion and es_directriz and abs(angulo_direccion) > 0.01 and abs(vel_forward) > 0.5:
		var velocidad_factor: float = min(abs(vel_forward) / 10.0, 1.0)
		var torque_direccion: float = angulo_direccion * torque_asistencia_direccion * velocidad_factor * (fuerza_normal_total / 10000.0)
		coche.apply_torque(up * torque_direccion)

# ════════════════════════════════════════════════════════════════════
# SUSPENSIÓN SIN CONTACTO
# ════════════════════════════════════════════════════════════════════

func _aplicar_suspension_libre(delta: float) -> void:
	compresion_anterior = 0.0
	velocidad_suspension = 0.0
	fuerza_normal_anterior = 0.0
	
	if rueda_visual:
		var ty: float = -largo_reposo + radio_rueda
		rueda_visual.position.y = lerp(rueda_visual.position.y, ty, delta * 5.0)

# ════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN VISUAL
# ════════════════════════════════════════════════════════════════════

func _actualizar_visual(delta: float) -> void:
	if not rueda_visual:
		return

	# Altura según colisión
	var ty: float = -largo_reposo + radio_rueda
	if is_colliding():
		ty = to_local(get_collision_point()).y + radio_rueda
	rueda_visual.position.y = lerp(rueda_visual.position.y, ty, delta * 20.0)

	# Dirección (solo visual)
	# En este rig la malla de la rueda está invertida respecto al ángulo físico.
	var q_direccion: Quaternion = Quaternion(Vector3.UP, -angulo_direccion)

	# Rodado visual
	angulo_rodado_visual -= vel_rodado_visual * delta / max(radio_rueda, 0.05)
	angulo_rodado_visual = wrapf(angulo_rodado_visual, -PI, PI)
	var q_rodado: Quaternion = Quaternion(Vector3.RIGHT, angulo_rodado_visual)

	rueda_visual.quaternion = q_direccion * rotacion_visual_base * q_rodado

# ════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════════════════

func set_drive_torque(t: float) -> void:
	torque_drive = t

func set_brake(intensidad: float, mano: bool) -> void:
	intensidad = clamp(intensidad, 0.0, 1.0)
	if mano:
		fuerza_freno_mano = intensidad * fuerza_max_freno * 1.5
		fuerza_freno = 0.0
	else:
		fuerza_freno = intensidad * fuerza_max_freno
		fuerza_freno_mano = 0.0

func aplicar_angulo_direccion(angulo: float) -> void:
	angulo_direccion = angulo

func _buscar_coche(n: Node) -> RigidBody3D:
	if n == null or n is RigidBody3D:
		return n
	return _buscar_coche(n.get_parent())
