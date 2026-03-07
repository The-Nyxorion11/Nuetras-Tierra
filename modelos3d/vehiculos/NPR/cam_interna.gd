# cam_interna.gd
# Cámara en primera persona para el conductor adaptada a Mouse Libre.
extends Camera3D

@export_group("Referencias")
@export var controlador_chasis: Node3D
@export var motor_nodo: NodePath

@export_group("Límites de Mirada")
@export var sensibilidad: float = 0.14
@export var limite_v: Vector2 = Vector2(-65.0, 65.0)
@export var limite_h: Vector2 = Vector2(-145.0, 145.0)
@export var auto_centrado_fuerza: float = 1.8

@export_group("Asomarse por Ventana")
@export var angulo_asomarse: float = 95.0
@export var distancia_asomada: float = 0.4

@export_group("Efectos Dinámicos")
@export var intensidad_vibracion: float = 0.012
@export var look_ahead_curvas: float = 0.12
@export var intensidad_g: float = 0.06
@export var suavizado_g: float = 8.0

var rot_x: float = 0.0
var rot_y: float = 0.0
var vel_previa: Vector3 = Vector3.ZERO
var pos_original: Vector3
var tiempo_sin_mouse: float = 0.0
var _offset_cabeza: Vector3 = Vector3.ZERO

@onready var coche: RigidBody3D = get_owner()
var motor_nodo_ref: Node

func _ready() -> void:
	pos_original = position
	
	# --- CAMBIO: NO CAPTURAR EL MOUSE ---
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if motor_nodo:
		motor_nodo_ref = get_node_or_null(motor_nodo)
	
	# --- CONEXIÓN CON LA UI ---
	# Buscamos la ZonaCamara para recibir el movimiento del mouse libre
	var ui_pie = get_tree().root.find_child("UIpie", true, false)
	if ui_pie:
		var zona = ui_pie.get_node_or_null("Controles/ZonaCamara")
		if zona:
			# Conectamos la señal de la zona táctil a nuestra nueva función
			if not zona.camara_movida.is_connected(_manejar_rotacion_libre):
				zona.camara_movida.connect(_manejar_rotacion_libre)

func _input(_event: InputEvent) -> void:
	if not current:
		return
	
	# Eliminamos el bloque InputEventMouseMotion que requería captura.
	# Ahora la rotación viene de la señal de la ZonaCamara.
	pass

# --- NUEVA FUNCIÓN PARA MOUSE LIBRE ---
func _manejar_rotacion_libre(relative: Vector2) -> void:
	if not current: return
	
	tiempo_sin_mouse = 0.0
	rot_y -= relative.x * sensibilidad
	rot_x -= relative.y * sensibilidad
	
	# Aplicar límites
	rot_x = clamp(rot_x, limite_v.x, limite_v.y)
	rot_y = clamp(rot_y, limite_h.x, limite_h.y)

func _physics_process(delta: float) -> void:
	if not current or not coche:
		return

	# ── AUTO-CENTRADO ────────────────────────────────────────────────────────
	tiempo_sin_mouse += delta
	if tiempo_sin_mouse > 1.8:
		rot_y = lerp(rot_y, 0.0, delta * auto_centrado_fuerza)
		rot_x = lerp(rot_x, 0.0, delta * auto_centrado_fuerza * 0.5)

	# ── FUERZAS G (Inercia de la cabeza) ────────────────────────────────────
	var inv_basis: Basis = coche.global_transform.basis.inverse()
	var acc_global: Vector3 = (coche.linear_velocity - vel_previa) / delta
	vel_previa = coche.linear_velocity
	var acc_local: Vector3 = inv_basis * acc_global

	var target_offset: Vector3 = Vector3(
		-acc_local.x * 0.0008 * intensidad_g,   # Lateral
		-abs(acc_local.x) * 0.0004,              # Se hunde en curvas
		acc_local.z * 0.0012 * intensidad_g      # Freno/aceleración
	)
	_offset_cabeza = _offset_cabeza.lerp(target_offset, delta * suavizado_g)

	# ── VIBRACIÓN DE MOTOR ───────────────────────────────────────────────────
	var vibracion: Vector3 = Vector3.ZERO
	var pitch_actual: float = 1.0
	if motor_nodo_ref:
		for hijo in motor_nodo_ref.get_children():
			if hijo is AudioStreamPlayer3D:
				pitch_actual = hijo.pitch_scale
				break
	
	var factor_vib: float = clamp(pitch_actual * 0.08 + coche.linear_velocity.length() * 0.005, 0.0, 1.0)
	vibracion.x = randf_range(-intensidad_vibracion, intensidad_vibracion) * factor_vib
	vibracion.y = randf_range(-intensidad_vibracion, intensidad_vibracion) * factor_vib

	# ── ASOMARSE POR VENTANA ─────────────────────────────────────────────────
	var target_pos: Vector3 = pos_original + _offset_cabeza + vibracion
	if rot_y > angulo_asomarse:
		var factor: float = clamp((rot_y - angulo_asomarse) / 45.0, 0.0, 1.0)
		target_pos.x -= distancia_asomada * factor
		target_pos.z += distancia_asomada * 0.25 * factor
	elif rot_y < -angulo_asomarse:
		var factor: float = clamp((-rot_y - angulo_asomarse) / 45.0, 0.0, 1.0)
		target_pos.x += distancia_asomada * factor
		target_pos.z += distancia_asomada * 0.25 * factor

	position = position.lerp(target_pos, delta * 20.0)

	# ── ROTACIÓN ────────────────────────────────────────────────────────────
	var rot_obj_y: float = rot_y
	var angular_local: Vector3 = inv_basis * coche.angular_velocity
	rot_obj_y -= angular_local.y * rad_to_deg(look_ahead_curvas)

	var rot_final: Vector3 = Vector3(deg_to_rad(rot_x), deg_to_rad(rot_obj_y), 0.0)

	if controlador_chasis:
		var bal: Vector3 = controlador_chasis.rotation
		rot_final.z = -bal.z * 0.55
		rot_final.x += bal.x * 0.25

	rotation = rotation.lerp(rot_final, delta * 18.0)

	# ── FOV DINÁMICO ────────────────────────────────────────────────────────
	var kmh: float = coche.linear_velocity.length() * 3.6
	fov = lerp(fov, 72.0 + clamp(kmh * 0.12, 0.0, 25.0), delta * 2.5)
