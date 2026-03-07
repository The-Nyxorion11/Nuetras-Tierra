extends CanvasLayer
class_name ConfiguracionesUI

@onready var panel_config: Panel = get_node_or_null("PanelConfiguraciones")
@onready var btn_volver: Button = get_node_or_null("PanelConfiguraciones/BtnVolver")
@onready var btn_guardar: Button = get_node_or_null("PanelConfiguraciones/BtnGuardar")
@onready var btn_restaurar: Button = get_node_or_null("PanelConfiguraciones/BtnRestaurar")

@onready var slider_calidad_graficos: HSlider = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/SliderCalidadGraficos")
@onready var chk_sombras: CheckButton = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/CheckSombras")
@onready var chk_reflejos: CheckButton = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/CheckReflejos")

@onready var slider_volumen_general: HSlider = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/SliderVolumenGeneral")
@onready var slider_volumen_musica: HSlider = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/SliderVolumenMusica")
@onready var slider_volumen_efectos: HSlider = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/SliderVolumenEfectos")

@onready var chk_subtitulos: CheckButton = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/CheckSubtitulos")
@onready var slider_sensibilidad_camara: HSlider = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/SliderSensibilidadCamara")
@onready var option_dificultad: OptionButton = get_node_or_null("PanelConfiguraciones/MarginContainer/VBoxContainer/OptionDificultad")

var configuraciones_actuales: Dictionary = {
	"graficos": {
		"calidad": 2,
		"sombras": true,
		"reflejos": true,
	},
	"audio": {
		"volumen_general": 80,
		"volumen_musica": 70,
		"volumen_efectos": 80,
	},
	"juego": {
		"subtitulos": true,
		"sensibilidad_camara": 50,
		"dificultad": 1,
	},
}

var configuraciones_por_defecto: Dictionary = configuraciones_actuales.duplicate(true)

func _ready() -> void:
	_conectar_senales()
	_cargar_configuraciones()
	_actualizar_ui()

func _conectar_senales() -> void:
	if btn_volver:
		btn_volver.pressed.connect(_on_btn_volver_pressed)
	if btn_guardar:
		btn_guardar.pressed.connect(_on_btn_guardar_pressed)
	if btn_restaurar:
		btn_restaurar.pressed.connect(_on_btn_restaurar_pressed)
	
	if slider_calidad_graficos:
		slider_calidad_graficos.value_changed.connect(_on_calidad_graficos_changed)
	if chk_sombras:
		chk_sombras.toggled.connect(_on_sombras_toggled)
	if chk_reflejos:
		chk_reflejos.toggled.connect(_on_reflejos_toggled)
	
	if slider_volumen_general:
		slider_volumen_general.value_changed.connect(_on_volumen_general_changed)
	if slider_volumen_musica:
		slider_volumen_musica.value_changed.connect(_on_volumen_musica_changed)
	if slider_volumen_efectos:
		slider_volumen_efectos.value_changed.connect(_on_volumen_efectos_changed)
	
	if chk_subtitulos:
		chk_subtitulos.toggled.connect(_on_subtitulos_toggled)
	if slider_sensibilidad_camara:
		slider_sensibilidad_camara.value_changed.connect(_on_sensibilidad_camara_changed)
	if option_dificultad:
		option_dificultad.item_selected.connect(_on_dificultad_seleccionada)

func _cargar_configuraciones() -> void:
	# Buscar ConfigManager en /root
	var config_mgr = get_tree().root.get_node_or_null("ConfigManager")
	
	if config_mgr != null and config_mgr.has_method("obtener_seccion"):
		for seccion in ["graficos", "audio", "juego"]:
			var sec_config = config_mgr.obtener_seccion(seccion)
			if sec_config:
				configuraciones_actuales[seccion] = sec_config
		print("[UI] Configuraciones cargadas")
	else:
		print("[UI] ConfigManager no disponible, valores por defecto")

func _guardar_configuraciones() -> void:
	var config_mgr = get_tree().root.get_node_or_null("ConfigManager")
	
	if config_mgr != null and config_mgr.has_method("establecer"):
		for seccion in configuraciones_actuales.keys():
			if configuraciones_actuales[seccion] is Dictionary:
				for clave in configuraciones_actuales[seccion].keys():
					var valor = configuraciones_actuales[seccion][clave]
					config_mgr.establecer(seccion, clave, valor, false)
		print("[UI] Guardado")

func _actualizar_ui() -> void:
	if slider_calidad_graficos:
		slider_calidad_graficos.value = configuraciones_actuales["graficos"]["calidad"]
	if chk_sombras:
		chk_sombras.button_pressed = configuraciones_actuales["graficos"]["sombras"]
	if chk_reflejos:
		chk_reflejos.button_pressed = configuraciones_actuales["graficos"]["reflejos"]
	
	if slider_volumen_general:
		slider_volumen_general.value = configuraciones_actuales["audio"]["volumen_general"]
	if slider_volumen_musica:
		slider_volumen_musica.value = configuraciones_actuales["audio"]["volumen_musica"]
	if slider_volumen_efectos:
		slider_volumen_efectos.value = configuraciones_actuales["audio"]["volumen_efectos"]
	
	if chk_subtitulos:
		chk_subtitulos.button_pressed = configuraciones_actuales["juego"]["subtitulos"]
	if slider_sensibilidad_camara:
		slider_sensibilidad_camara.value = configuraciones_actuales["juego"]["sensibilidad_camara"]
	if option_dificultad:
		option_dificultad.select(configuraciones_actuales["juego"]["dificultad"])

func _on_calidad_graficos_changed(valor: float) -> void:
	configuraciones_actuales["graficos"]["calidad"] = int(valor)
	_aplicar_calidad_graficos(int(valor))

func _on_sombras_toggled(activada: bool) -> void:
	configuraciones_actuales["graficos"]["sombras"] = activada

func _on_reflejos_toggled(activada: bool) -> void:
	configuraciones_actuales["graficos"]["reflejos"] = activada

func _on_volumen_general_changed(valor: float) -> void:
	configuraciones_actuales["audio"]["volumen_general"] = int(valor)
	_aplicar_volumen_general(int(valor))

func _on_volumen_musica_changed(valor: float) -> void:
	configuraciones_actuales["audio"]["volumen_musica"] = int(valor)
	_aplicar_volumen_musica(int(valor))

func _on_volumen_efectos_changed(valor: float) -> void:
	configuraciones_actuales["audio"]["volumen_efectos"] = int(valor)
	_aplicar_volumen_efectos(int(valor))

func _on_subtitulos_toggled(activados: bool) -> void:
	configuraciones_actuales["juego"]["subtitulos"] = activados

func _on_sensibilidad_camara_changed(valor: float) -> void:
	configuraciones_actuales["juego"]["sensibilidad_camara"] = int(valor)

func _on_dificultad_seleccionada(indice: int) -> void:
	configuraciones_actuales["juego"]["dificultad"] = indice

func _aplicar_calidad_graficos(nivel: int) -> void:
	match nivel:
		0:
			print("[Graficos] Baja")
		1:
			print("[Graficos] Media")
		2:
			print("[Graficos] Alta")

func _aplicar_volumen_general(volumen: int) -> void:
	AudioServer.set_bus_mute(0, volumen == 0)
	if volumen > 0:
		var db = linear_to_db(volumen / 100.0)
		AudioServer.set_bus_volume_db(0, db)
	print("[Audio] General: ", volumen, "%")

func _aplicar_volumen_musica(volumen: int) -> void:
	var bus_idx = AudioServer.get_bus_index("Musica")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, volumen == 0)
		if volumen > 0:
			var db = linear_to_db(volumen / 100.0)
			AudioServer.set_bus_volume_db(bus_idx, db)
	print("[Audio] Musica: ", volumen, "%")

func _aplicar_volumen_efectos(volumen: int) -> void:
	var bus_idx = AudioServer.get_bus_index("Efectos")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, volumen == 0)
		if volumen > 0:
			var db = linear_to_db(volumen / 100.0)
			AudioServer.set_bus_volume_db(bus_idx, db)
	print("[Audio] Efectos: ", volumen, "%")

func _on_btn_guardar_pressed() -> void:
	_guardar_configuraciones()

func _on_btn_restaurar_pressed() -> void:
	configuraciones_actuales = configuraciones_por_defecto.duplicate(true)
	_guardar_configuraciones()
	_actualizar_ui()

func _on_btn_volver_pressed() -> void:
	hide()
	_guardar_configuraciones()

func mostrar_configuraciones() -> void:
	show()
	_actualizar_ui()

func ocultar_configuraciones() -> void:
	hide()
