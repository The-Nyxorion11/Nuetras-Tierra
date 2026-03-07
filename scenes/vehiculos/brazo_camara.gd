extends Node3D

@export_group("Configuración")
@export var objetivo: Node3D
@export var sensibilidad: float = 0.25 # Subida un poco para mejor respuesta
@export var suavizado: float = 12.0
@export var altura_offset: float = 1.5

@export_group("Zoom")
@export var largo_min: float = 3.5
@export var largo_max: float = 15.0

@export_group("Inercia y Seguimiento")
@export var intensidad_g: float = 0.15
@export var seguimiento_yaw: float = 0.4 

@onready var brazo: SpringArm3D = $SpringArm3D

# Estado interno
var rot_x: float = -15.0
var rot_y: float = 0.0
var esta_activa: bool = true # Asegúrate de que coche.gd la active
var coche: RigidBody3D
var offset_inercia: Vector3 = Vector3.ZERO
var _yaw_coche_prev: float = 0.0

func _ready() -> void:
	if objetivo is RigidBody3D:
		coche = objetivo
	elif get_parent() is RigidBody3D:
		coche = get_parent()
		objetivo = coche

	if brazo:
		brazo.spring_length = 6.0
		# Importante: Que el brazo no choque con el camión
		if objetivo:
			brazo.add_excluded_object(objetivo.get_rid())
	
	if coche:
		_yaw_coche_prev = coche.global_rotation.y
		rot_y = rad_to_deg(coche.global_rotation.y)

# --- FUNCIÓN CRÍTICA: Aquí es donde recibimos el movimiento del mouse/touch ---
func _on_camara_movida(relative: Vector2) -> void:
	# Si esto no se ejecuta, el problema está en la señal de coche.gd
	rot_y -= relative.x * sensibilidad
	rot_x -= relative.y * sensibilidad
	
	# Clamp corregido para permitir mirar hacia arriba y abajo razonablemente
	rot_x = clamp(rot_x, -70.0, 20.0) 

func _input(event: InputEvent) -> void:
	# Zoom con la rueda del ratón
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			brazo.spring_length = clamp(brazo.spring_length - 0.5, largo_min, largo_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brazo.spring_length = clamp(brazo.spring_length + 0.5, largo_min, largo_max)

func _physics_process(delta: float) -> void:
	if not objetivo or not brazo: return

	# 1. POSICIÓN: El seguidor (este nodo) sigue al camión
	global_position = global_position.lerp(objetivo.global_position + Vector3.UP * altura_offset, suavizado * delta)

	# 2. SEGUIMIENTO AUTOMÁTICO DE GIRO (Opcional, se puede comentar para control total)
	if coche:
		var yaw_coche = coche.global_rotation.y
		var delta_yaw = fmod(yaw_coche - _yaw_coche_prev + PI, TAU) - PI
		_yaw_coche_prev = yaw_coche
		rot_y += rad_to_deg(delta_yaw) * seguimiento_yaw

	# 3. APLICAR ROTACIONES
	# La rotación horizontal (Y) se aplica a ESTE NODO (el padre)
	rotation_degrees.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(rot_y), delta * 20.0)
	rotation_degrees.y = rad_to_deg(rotation_degrees.y)
	
	# La rotación vertical (X) se aplica al BRAZO (el hijo)
	brazo.rotation_degrees.x = rot_x

	# 4. INERCIA (Efecto visual de peso al acelerar/girar)
	if coche:
		var vel_local = coche.global_transform.basis.inverse() * coche.linear_velocity
		var target_inercia = Vector3(
			-vel_local.x * 0.02 * intensidad_g, 
			0, 
			vel_local.z * 0.01 * intensidad_g 
		)
		offset_inercia = offset_inercia.lerp(target_inercia, delta * 5.0)
		
		# Aplicamos la inercia solo a la cámara para no romper la rotación del brazo
		var cam = brazo.get_child(0)
		if cam is Camera3D:
			cam.transform.origin = offset_inercia
