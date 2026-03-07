extends ColorRect

@export var nombre_pedal: String = "acelerador" 
@export var sensibilidad_retorno: float = 8.0 
@export var sensibilidad_presion: float = 12.0 

var presion_actual: float = 0.0
var presion_objetivo: float = 0.0
var tocando: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if material is ShaderMaterial:
		material.set_shader_parameter("es_freno", nombre_pedal.to_lower().contains("freno"))

func _gui_input(event: InputEvent) -> void:
	var es_presion = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch
	var es_movimiento = event is InputEventMouseMotion or event is InputEventScreenDrag

	if es_presion:
		tocando = event.pressed
		if tocando: _calcular_objetivo(event.position)
	elif es_movimiento and tocando:
		_calcular_objetivo(event.position)

func _calcular_objetivo(pos_local: Vector2) -> void:
	presion_objetivo = clamp(pos_local.y / size.y, 0.0, 1.0)

func _process(delta: float) -> void:
	var vel = sensibilidad_presion if tocando else sensibilidad_retorno
	presion_actual = move_toward(presion_actual, (presion_objetivo if tocando else 0.0), delta * vel)
	
	if material is ShaderMaterial:
		material.set_shader_parameter("presionado", tocando)
		material.set_shader_parameter("intensidad_presion", presion_actual)
	
	# ENVIAR DATOS (Asegúrate que InputVehiculo sea un Autoload)
	if is_instance_valid(InputVehiculo):
		var valor = pow(presion_actual, 1.5) if nombre_pedal.to_lower().contains("freno") else presion_actual
		if nombre_pedal.to_lower().contains("aceler"):
			InputVehiculo.set_gas(valor)
			# DEBUG: Ver aceleración
			if valor > 0.1 and Engine.get_frames_drawn() % 60 == 0:
				print("Pedal acelerador: %.2f" % valor)
		elif nombre_pedal.to_lower().contains("freno"):
			InputVehiculo.set_freno(valor)
