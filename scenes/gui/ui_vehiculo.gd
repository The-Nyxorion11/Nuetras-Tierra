# ui_vehiculo.gd
extends CanvasLayer

@export var vehiculo_path: NodePath

# --- VARIABLES DE ESTADO ---
var vehiculo: RigidBody3D
var _motor_ref: Node
const COOLDOWN_CAMARA_MS: int = 180
var _ultimo_cambio_camara_ms: int = -10000

# --- NODOS DE UI ---
@onready var label_marcha     = get_node_or_null("SafeArea/Interface/DisplayMarcha")
@onready var label_velocidad  = $SafeArea/Interface/DisplayVelocidad
@onready var boton_motor      = %BotonMotor
@onready var boton_freno_mano = %BotonFrenoMano
@onready var boton_salir      = %BotonSalir
@onready var boton_camara     = %BotonCamara

# Nuevo selector de marchas con 4 botones
@onready var selector_marchas = $SafeArea/Interface/SelectorMarchas
@onready var boton_centrar    = get_node_or_null("SafeArea/Interface/PanelVolante/BotonCentrar")
@onready var volante_control  = $SafeArea/Interface/PanelVolante/Volante

# Shader para botones
@export var color_boton_activo: Color = Color.YELLOW
@export var color_boton_inactivo: Color = Color.WHITE
@export var brillo_boton_activo: float = 1.4

# ════════════════════════════════════════════════════════════════════
#  INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════════

func _ready() -> void:
	self.visible = false

	# Localizar el vehículo
	if vehiculo_path and not vehiculo_path.is_empty():
		vehiculo = get_node(vehiculo_path)
	elif get_parent() is RigidBody3D:
		vehiculo = get_parent()

	if vehiculo:
		_motor_ref = vehiculo.get_node_or_null("Motor")
		if not _motor_ref:
			push_warning("UIVehiculo: No se encontró el nodo 'Motor' en el vehículo.")

	# Aplicar shader a los botones
	_aplicar_shader_botones()

	# Conectar botones
	if boton_camara:
		if not boton_camara.pressed.is_connected(_on_cambiar_camara):
			boton_camara.pressed.connect(_on_cambiar_camara)

	if boton_motor:
		if not boton_motor.toggled.is_connected(_on_boton_motor_toggle):
			boton_motor.toggled.connect(_on_boton_motor_toggle)

	if boton_freno_mano:
		if not boton_freno_mano.button_down.is_connected(_on_freno_mano_down):
			boton_freno_mano.button_down.connect(_on_freno_mano_down)
		if not boton_freno_mano.button_up.is_connected(_on_freno_mano_up):
			boton_freno_mano.button_up.connect(_on_freno_mano_up)

	if boton_salir:
		if not boton_salir.pressed.is_connected(_on_boton_salir):
			boton_salir.pressed.connect(_on_boton_salir)
	
	# Conectar botón de centrar volante
	if boton_centrar:
		if not boton_centrar.pressed.is_connected(_on_centrar_volante):
			boton_centrar.pressed.connect(_on_centrar_volante)

func _aplicar_shader_botones() -> void:
	# Crear y aplicar shader al botón de motor
	if boton_motor:
		var material = ShaderMaterial.new()
		material.shader = load("res://scenes/gui/BotonVehiculo.gdshader")
		material.set_shader_parameter("color_activo", color_boton_activo)
		material.set_shader_parameter("color_inactivo", color_boton_inactivo)
		material.set_shader_parameter("brillo_activo", brillo_boton_activo)
		material.set_shader_parameter("activo", false)
		# Aplicar a través de custom theme o modulate
		boton_motor.self_modulate = Color.WHITE
	
	if boton_freno_mano:
		boton_freno_mano.self_modulate = Color.WHITE

# ════════════════════════════════════════════════════════════════════
#  ACTUALIZACIÓN DE UI
# ════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if not visible or not vehiculo:
		return

	# Mostrar Marcha Actual
	if label_marcha:
		label_marcha.text = _get_texto_marcha()

	# Velocidad en KM/H
	var kmh: int = int(vehiculo.linear_velocity.length() * 3.6)
	if label_velocidad:
		label_velocidad.text = str(kmh) + " km/h"
	
	# Actualizar color del botón de motor
	_actualizar_color_botones()

# ════════════════════════════════════════════════════════════════════
#  EVENTOS DE BOTONES
# ════════════════════════════════════════════════════════════════════

func _on_cambiar_camara() -> void:
	var ahora_ms: int = Time.get_ticks_msec()
	if ahora_ms - _ultimo_cambio_camara_ms < COOLDOWN_CAMARA_MS:
		return
	_ultimo_cambio_camara_ms = ahora_ms
	if GameManager and GameManager.has_method("cambiar_camara_global"):
		GameManager.cambiar_camara_global()

func _on_boton_motor_toggle(activo: bool) -> void:
	if not is_instance_valid(InputVehiculo):
		return
	InputVehiculo.set_motor_encendido(activo)

func _on_freno_mano_down() -> void:
	if not is_instance_valid(InputVehiculo):
		return
	InputVehiculo.freno_mano = true

func _on_freno_mano_up() -> void:
	if not is_instance_valid(InputVehiculo):
		return
	InputVehiculo.freno_mano = false

func _on_boton_salir() -> void:
	if vehiculo:
		var jugador = vehiculo.get("jugador_ref")
		if jugador and jugador.has_method("salir_del_vehiculo"):
			jugador.salir_del_vehiculo()
			return
	if vehiculo and vehiculo.has_method("bajar_jugador"):
		vehiculo.bajar_jugador()

func _on_centrar_volante() -> void:
	if is_instance_valid(InputVehiculo):
		InputVehiculo.centrar_direccion()
	if volante_control and volante_control.has_method("centrar_volante"):
		volante_control.centrar_volante()

# ════════════════════════════════════════════════════════════════════
#  UTILIDADES
# ════════════════════════════════════════════════════════════════════

func _actualizar_color_botones() -> void:
	# Actualizar shader del botón de motor
	if boton_motor and boton_motor.material is ShaderMaterial:
		boton_motor.material.set_shader_parameter("activo", boton_motor.button_pressed)
	
	# Actualizar shader del botón de freno mano
	if boton_freno_mano and boton_freno_mano.material is ShaderMaterial:
		boton_freno_mano.material.set_shader_parameter("activo", boton_freno_mano.button_pressed)

func _get_texto_marcha() -> String:
	if not is_instance_valid(InputVehiculo):
		return "N"
	return InputVehiculo.marcha

