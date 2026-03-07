extends Button

@export var accion_nombre: String = "interactuar"

var _touch_index: int = -1

func _ready():
	focus_mode  = FocusMode.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	pivot_offset = size / 2
	
	# Usar _input en lugar de _gui_input para capturar antes del joystick
	# y poder verificar mejor qué está ocupando el toque

	# Conexiones para PC/Editor
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# Solo capturar si estamos libres y el toque está en nuestra área
			if _touch_index == -1 and get_global_rect().abs().has_point(event.position):
				# Verificar que joystick y zona_camara no tengan ese dedo
				var zona_cam  = get_tree().get_first_node_in_group("zona_camara")
				if zona_cam and zona_cam.finger_id == event.index:
					return
				
				# NO verificar el joystick aquí - permitir que el botón tenga prioridad
				# si el toque está claramente sobre él
				_touch_index = event.index
				_presionar()
				get_viewport().set_input_as_handled()
		else:
			if event.index == _touch_index:
				_touch_index = -1
				_soltar()
				get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	# Redundancia: en caso de que _input no capture el evento
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and get_global_rect().abs().has_point(event.position):
				_touch_index = event.index
				_presionar()
				get_viewport().set_input_as_handled()
		else:
			if event.index == _touch_index:
				_touch_index = -1
				_soltar()
				get_viewport().set_input_as_handled()

func _presionar() -> void:
	Input.action_press(accion_nombre)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(0.85, 0.85), 0.05)

func _soltar() -> void:
	Input.action_release(accion_nombre)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

# PC / Editor
func _on_button_down() -> void:
	if not OS.has_feature("mobile"):
		_presionar()

func _on_button_up() -> void:
	if not OS.has_feature("mobile"):
		_soltar()

func _exit_tree() -> void:
	if Input.is_action_pressed(accion_nombre):
		Input.action_release(accion_nombre)
