# ui_menu_button.gd - Botón para abrir el menú principal
# Sistema completamente nuevo - simple y efectivo
extends Button

var _touch_index: int = -1

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	focus_mode = FocusMode.FOCUS_NONE
	pressed.connect(_on_pressed)

# ════════════════════════════════════════════════════════════════
# INPUT HANDLING
# ════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and get_global_rect().abs().has_point(event.position):
				_touch_index = event.index
				_on_pressed()
				get_tree().root.set_input_as_handled()
		else:
			if event.index == _touch_index:
				_touch_index = -1
				get_tree().root.set_input_as_handled()

	if event.is_action_pressed("ui_select"):
		_on_pressed()
		get_tree().root.set_input_as_handled()

# ════════════════════════════════════════════════════════════════
# EVENTOS
# ════════════════════════════════════════════════════════════════
func _on_pressed() -> void:
	var menu_system = get_node("/root/MenuSystem")
	if menu_system and not menu_system.menu_abierto:
		menu_system.abrir_menu()
