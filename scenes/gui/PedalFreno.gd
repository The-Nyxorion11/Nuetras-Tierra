extends ColorRect

@export var nombre_pedal: String = "freno"
@export var sensibilidad_retorno: float = 6.0  # Más lento que el gas para sentir peso
@export var sensibilidad_presion: float = 10.0 

var presion_actual: float = 0.0
var presion_objetivo: float = 0.0
var tocando: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if material is ShaderMaterial:
		material.set_shader_parameter("es_freno", true)

func _gui_input(event: InputEvent) -> void:
	var es_presion = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch
	var es_movimiento = event is InputEventMouseMotion or event is InputEventScreenDrag

	if es_presion:
		tocando = event.pressed
		if tocando: _actualizar_presion(event.position)
	elif es_movimiento and tocando:
		_actualizar_presion(event.position)

func _actualizar_presion(pos_local: Vector2) -> void:
	# Mapeo: Tocar más abajo aumenta la presión
	presion_objetivo = clamp(pos_local.y / size.y, 0.0, 1.0)

func _process(delta: float) -> void:
	var vel = sensibilidad_presion if tocando else sensibilidad_retorno
	presion_actual = move_toward(presion_actual, (presion_objetivo if tocando else 0.0), delta * vel)
	
	# Actualizar Shader
	if material is ShaderMaterial:
		material.set_shader_parameter("presionado", tocando)
		material.set_shader_parameter("intensidad_presion", presion_actual)
	
	# Enviar al Singleton de Input
	if is_instance_valid(InputVehiculo):
		# Curva exponencial para que el freno "muerda" más fuerte al final
		var fuerza_freno = pow(presion_actual, 1.5)
		InputVehiculo.set_freno(fuerza_freno)

func reset_pedal():
	presion_actual = 0.0
	presion_objetivo = 0.0
	tocando = false
