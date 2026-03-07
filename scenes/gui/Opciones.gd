# Opciones.gd - Panel de configuración del juego
extends Control

# ════════════════════════════════════════════════════════════════
# REFERENCIAS - AUDIO
# ════════════════════════════════════════════════════════════════
@onready var slider_volumen_master: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/SliderVolumenMaster
@onready var slider_volumen_musica: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/SliderVolumenMusica
@onready var slider_volumen_sfx: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/SliderVolumenSFX
@onready var slider_volumen_ambiente: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/SliderVolumenAmbiente
@onready var lbl_volumen_master: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/LblVolumenMaster
@onready var lbl_volumen_musica: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/LblVolumenMusica
@onready var lbl_volumen_sfx: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/LblVolumenSFX
@onready var lbl_volumen_ambiente: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Audio/VBoxAudio/LblVolumenAmbiente

# ════════════════════════════════════════════════════════════════
# REFERENCIAS - VIDEO
# ════════════════════════════════════════════════════════════════
@onready var check_pantalla_completa: CheckButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Video/VBoxVideo/CheckPantallaCompleta
@onready var check_vsync: CheckButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Video/VBoxVideo/CheckVSync
@onready var slider_brillo: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Video/VBoxVideo/SliderBrillo
@onready var lbl_brillo: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Video/VBoxVideo/LblBrillo
@onready var option_calidad_sombras: OptionButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Video/VBoxVideo/OptionCalidadSombras

# ════════════════════════════════════════════════════════════════
# REFERENCIAS - HUD
# ════════════════════════════════════════════════════════════════
@onready var check_mostrar_fps: CheckButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/HUD/VBoxHUD/CheckMostrarFPS
@onready var check_mostrar_minimapa: CheckButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/HUD/VBoxHUD/CheckMostrarMiniMapa
@onready var slider_tamaño_hud: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/HUD/VBoxHUD/SliderTamañoHUD
@onready var slider_opacidad_hud: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/HUD/VBoxHUD/SliderOpacidadHUD
@onready var lbl_tamaño_hud: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/HUD/VBoxHUD/LblTamañoHUD
@onready var lbl_opacidad_hud: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/HUD/VBoxHUD/LblOpacidadHUD

# ════════════════════════════════════════════════════════════════
# REFERENCIAS - GAMEPLAY
# ════════════════════════════════════════════════════════════════
@onready var slider_sensibilidad_camara: HSlider = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Gameplay/VBoxGameplay/SliderSensibilidadCamara
@onready var check_invertir_camara: CheckButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Gameplay/VBoxGameplay/CheckInvertirCamara
@onready var check_vibracion: CheckButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Gameplay/VBoxGameplay/CheckVibracion
@onready var option_dificultad: OptionButton = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Gameplay/VBoxGameplay/OptionDificultad
@onready var lbl_sensibilidad_camara: Label = $SafeArea/PanelOpciones/PanelMargin/VBox/TabContainer/Gameplay/VBoxGameplay/LblSensibilidadCamara

# ════════════════════════════════════════════════════════════════
# REFERENCIAS - BOTONES
# ════════════════════════════════════════════════════════════════
@onready var btn_cerrar_x: Button = $SafeArea/PanelOpciones/PanelMargin/VBox/Header/BtnCerrarX
@onready var btn_volver: Button = $SafeArea/PanelOpciones/PanelMargin/VBox/BtnVolver
@onready var btn_restablecer: Button = $SafeArea/PanelOpciones/PanelMargin/VBox/BotonesInferiores/BtnRestablecer
@onready var btn_aplicar: Button = $SafeArea/PanelOpciones/PanelMargin/VBox/BotonesInferiores/BtnAplicar

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicializar_opciones()
	_conectar_señales()
	_cargar_configuracion()

func _inicializar_opciones() -> void:
	# Inicializar OptionButtons
	option_calidad_sombras.clear()
	option_calidad_sombras.add_item("Baja")
	option_calidad_sombras.add_item("Media")
	option_calidad_sombras.add_item("Alta")
	option_calidad_sombras.add_item("Ultra")
	option_calidad_sombras.selected = 2
	
	option_dificultad.clear()
	option_dificultad.add_item("Fácil")
	option_dificultad.add_item("Normal")
	option_dificultad.add_item("Difícil")
	option_dificultad.selected = 1

func _conectar_señales() -> void:
	# Botones principales
	btn_cerrar_x.pressed.connect(_on_cerrar_presionado)
	btn_volver.pressed.connect(_on_cerrar_presionado)
	btn_restablecer.pressed.connect(_on_restablecer_presionado)
	btn_aplicar.pressed.connect(_on_aplicar_presionado)
	
	# Audio sliders
	slider_volumen_master.value_changed.connect(_on_volumen_master_cambiado)
	slider_volumen_musica.value_changed.connect(_on_volumen_musica_cambiado)
	slider_volumen_sfx.value_changed.connect(_on_volumen_sfx_cambiado)
	slider_volumen_ambiente.value_changed.connect(_on_volumen_ambiente_cambiado)
	
	# Video
	check_pantalla_completa.toggled.connect(_on_pantalla_completa_toggled)
	check_vsync.toggled.connect(_on_vsync_toggled)
	slider_brillo.value_changed.connect(_on_brillo_cambiado)
	
	# HUD
	check_mostrar_fps.toggled.connect(_on_mostrar_fps_toggled)
	slider_tamaño_hud.value_changed.connect(_on_tamaño_hud_cambiado)
	slider_opacidad_hud.value_changed.connect(_on_opacidad_hud_cambiado)
	
	# Gameplay
	slider_sensibilidad_camara.value_changed.connect(_on_sensibilidad_camara_cambiada)

# ════════════════════════════════════════════════════════════════
# CARGAR/GUARDAR CONFIGURACIÓN
# ════════════════════════════════════════════════════════════════
func _cargar_configuracion() -> void:
	# Cargar desde ConfiguracionManager o ConfigFile
	# Por ahora solo actualiza las etiquetas
	_actualizar_labels()

func _guardar_configuracion() -> void:
	# Guardar en ConfiguracionManager o ConfigFile
	print("[Opciones] Configuración guardada")

# ════════════════════════════════════════════════════════════════
# CALLBACKS - AUDIO
# ════════════════════════════════════════════════════════════════
func _on_volumen_master_cambiado(value: float) -> void:
	lbl_volumen_master.text = "Volumen General: %d%%" % int(value * 100)
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_volumen_musica_cambiado(value: float) -> void:
	lbl_volumen_musica.text = "Volumen Música: %d%%" % int(value * 100)
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_volumen_sfx_cambiado(value: float) -> void:
	lbl_volumen_sfx.text = "Volumen Efectos: %d%%" % int(value * 100)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_volumen_ambiente_cambiado(value: float) -> void:
	lbl_volumen_ambiente.text = "Volumen Ambiente: %d%%" % int(value * 100)
	var bus_idx = AudioServer.get_bus_index("Ambiente")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

# ════════════════════════════════════════════════════════════════
# CALLBACKS - VIDEO
# ════════════════════════════════════════════════════════════════
func _on_pantalla_completa_toggled(activado: bool) -> void:
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(activado: bool) -> void:
	if activado:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_brillo_cambiado(value: float) -> void:
	lbl_brillo.text = "Brillo: %d%%" % int(value * 100)
	# Aplicar brillo global (si tienes un WorldEnvironment)

# ════════════════════════════════════════════════════════════════
# CALLBACKS - HUD
# ════════════════════════════════════════════════════════════════
func _on_mostrar_fps_toggled(activado: bool) -> void:
	# Mostrar/ocultar FPS counter
	print("[Opciones] FPS Counter: ", activado)

func _on_tamaño_hud_cambiado(value: float) -> void:
	lbl_tamaño_hud.text = "Tamaño HUD: %d%%" % int(value * 100)
	# Aplicar escala al HUD

func _on_opacidad_hud_cambiado(value: float) -> void:
	lbl_opacidad_hud.text = "Opacidad HUD: %d%%" % int(value * 100)
	# Aplicar opacidad al HUD

# ════════════════════════════════════════════════════════════════
# CALLBACKS - GAMEPLAY
# ════════════════════════════════════════════════════════════════
func _on_sensibilidad_camara_cambiada(value: float) -> void:
	lbl_sensibilidad_camara.text = "Sensibilidad Cámara: %d%%" % int(value * 100)
	# Aplicar sensibilidad a la cámara

# ════════════════════════════════════════════════════════════════
# BOTONES
# ════════════════════════════════════════════════════════════════
func _on_cerrar_presionado() -> void:
	queue_free()

func _on_aplicar_presionado() -> void:
	_guardar_configuracion()
	print("[Opciones] Configuración aplicada")

func _on_restablecer_presionado() -> void:
	_restablecer_valores_por_defecto()
	print("[Opciones] Valores restablecidos")

func _restablecer_valores_por_defecto() -> void:
	# Audio
	slider_volumen_master.value = 1.0
	slider_volumen_musica.value = 1.0
	slider_volumen_sfx.value = 1.0
	slider_volumen_ambiente.value = 1.0
	
	# Video
	check_pantalla_completa.button_pressed = false
	check_vsync.button_pressed = true
	slider_brillo.value = 1.0
	option_calidad_sombras.selected = 2
	
	# HUD
	check_mostrar_fps.button_pressed = false
	check_mostrar_minimapa.button_pressed = true
	slider_tamaño_hud.value = 1.0
	slider_opacidad_hud.value = 1.0
	
	# Gameplay
	slider_sensibilidad_camara.value = 1.0
	check_invertir_camara.button_pressed = false
	check_vibracion.button_pressed = true
	option_dificultad.selected = 1
	
	_actualizar_labels()

func _actualizar_labels() -> void:
	lbl_volumen_master.text = "Volumen General: %d%%" % int(slider_volumen_master.value * 100)
	lbl_volumen_musica.text = "Volumen Música: %d%%" % int(slider_volumen_musica.value * 100)
	lbl_volumen_sfx.text = "Volumen Efectos: %d%%" % int(slider_volumen_sfx.value * 100)
	lbl_volumen_ambiente.text = "Volumen Ambiente: %d%%" % int(slider_volumen_ambiente.value * 100)
	lbl_brillo.text = "Brillo: %d%%" % int(slider_brillo.value * 100)
	lbl_tamaño_hud.text = "Tamaño HUD: %d%%" % int(slider_tamaño_hud.value * 100)
	lbl_opacidad_hud.text = "Opacidad HUD: %d%%" % int(slider_opacidad_hud.value * 100)
	lbl_sensibilidad_camara.text = "Sensibilidad Cámara: %d%%" % int(slider_sensibilidad_camara.value * 100)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_cerrar_presionado()
		get_viewport().set_input_as_handled()
