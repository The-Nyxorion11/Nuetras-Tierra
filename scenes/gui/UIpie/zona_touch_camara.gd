extends Control

signal camara_movida(relative_vector: Vector2)

var finger_id: int = -1

@onready var controles: Control = get_parent() as Control

func _toque_sobre_control(nombre: String, posicion_global: Vector2) -> bool:
	if not controles:
		return false
	var control := controles.get_node_or_null(nombre) as Control
	if not control or not control.visible:
		return false
	return control.get_global_rect().abs().has_point(posicion_global)

func _toque_sobre_boton_accion(posicion_global: Vector2) -> bool:
	return _toque_sobre_control("Interactuar", posicion_global) \
		or _toque_sobre_control("BotonSalto", posicion_global) \
		or _toque_sobre_control("BotonAgachar", posicion_global)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("zona_camara")

func get_finger_id() -> int:
	return finger_id

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger_id == -1:
				if _toque_sobre_boton_accion(event.position):
					return
				# Verificar que el joystick no tenga ese dedo
				var joystick = get_tree().get_first_node_in_group("joystick")
				if joystick and joystick.get("_touch_index") == event.index:
					return
				finger_id = event.index
				get_viewport().set_input_as_handled()
		else:
			if event.index == finger_id:
				finger_id = -1
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if event.index == finger_id:
			camara_movida.emit(event.relative)
			get_viewport().set_input_as_handled()
