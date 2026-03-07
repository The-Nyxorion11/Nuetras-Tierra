extends Button

func _ready():
	focus_mode = FocusMode.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	button_up.connect(_on_pressed)

func _on_pressed():
	GameManager.cambiar_camara_global()
