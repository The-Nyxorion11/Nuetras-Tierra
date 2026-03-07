# Archivo: camara_orbital.gd
extends Node3D

@export_group("Objetivo")
@export var objetivo: Node3D        # Arrastra aquí tu VehicleBase
@export var altura_offset: float = 1.0 # Para no mirar exactamente al suelo

@export_group("Sensibilidad")
@export var sensibilidad_mouse: float = 0.2
@export var suavizado: float = 10.0

@export_group("Zoom")
@export var distancia_minima: float = 2.0
@export var distancia_maxima: float = 15.0
@export var sensibilidad_zoom: float = 0.5

var rot_x: float = 0.0
var rot_y: float = 0.0
var distancia_actual: float = 5.0
var camara: Camera3D

func _ready() -> void:
	camara = get_child(0) as Camera3D
	# Capturar el ratón para que no se salga de la ventana
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	# Liberar ratón con la tecla ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Rotación con el ratón
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rot_y -= event.relative.x * sensibilidad_mouse
		rot_x -= event.relative.y * sensibilidad_mouse
		rot_x = clamp(rot_x, -80, 80) # Limitar para no dar la vuelta completa vertical

	# Zoom con la rueda del ratón
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distancia_actual -= sensibilidad_zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distancia_actual += sensibilidad_zoom
		distancia_actual = clamp(distancia_actual, distancia_minima, distancia_maxima)

func _physics_process(delta: float) -> void:
	if not objetivo: return

	# 1. Seguir la posición del objetivo suavemente
	var pos_objetivo = objetivo.global_position + Vector3.UP * altura_offset
	global_position = global_position.lerp(pos_objetivo, suavizado * delta)

	# 2. Aplicar rotación
	rotation_degrees.x = lerp_angle(deg_to_rad(rotation_degrees.x), deg_to_rad(rot_x), suavizado * delta)
	rotation_degrees.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(rot_y), suavizado * delta)
	
	rotation_degrees.x = rot_x
	rotation_degrees.y = rot_y

	# 3. Ajustar la distancia de la cámara (Zoom)
	if camara:
		camara.position.z = lerp(camara.position.z, distancia_actual, suavizado * delta)
