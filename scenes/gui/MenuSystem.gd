# MenuSystem.gd - Maneja apertura/cierre de menú con screenshot de fondo
extends Node

const ESC_TARGET_SCENE: String = "res://scenes/MainMenu.tscn"
const MENU_SCENE_PATH: String = "res://scenes/gui/MenuUI.tscn"

# ════════════════════════════════════════════════════════════════
# ESTADO
# ════════════════════════════════════════════════════════════════
var screenshot_imagen: Image = null
var menu_abierto: bool = false
var menu_instancia: Node = null
var canvas_layer_menu: CanvasLayer = null

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	print("[MenuSystem] Inicializado")

# ════════════════════════════════════════════════════════════════
# ABRIR MENÚ
# ════════════════════════════════════════════════════════════════
func abrir_menu() -> void:
	if menu_abierto:
		return
	
	menu_abierto = true
	print("[MenuSystem] Abriendo menú...")

	# Capturar pantalla
	await _capturar_screenshot()
	
	# Crear CanvasLayer para el menú
	canvas_layer_menu = CanvasLayer.new()
	canvas_layer_menu.layer = 100
	get_tree().root.add_child(canvas_layer_menu)
	
	# Instanciar MenuUI como overlay
	var menu_scene = load(MENU_SCENE_PATH)
	if menu_scene:
		menu_instancia = menu_scene.instantiate()
		canvas_layer_menu.add_child(menu_instancia)
		print("[MenuSystem] MenuUI instanciado como overlay")
	else:
		push_error("[MenuSystem] No se pudo cargar MenuUI.tscn")
		menu_abierto = false

# ════════════════════════════════════════════════════════════════
# CERRAR MENÚ (VOLVER AL JUEGO)
# ════════════════════════════════════════════════════════════════
func cerrar_menu() -> void:
	if not menu_abierto:
		return
	
	menu_abierto = false
	print("[MenuSystem] Cerrando menú y volviendo al juego...")
	
	# Remover menu del árbol (sin borrar la escena de juego)
	if menu_instancia and is_instance_valid(menu_instancia):
		menu_instancia.queue_free()
		menu_instancia = null
	
	if canvas_layer_menu and is_instance_valid(canvas_layer_menu):
		canvas_layer_menu.queue_free()
		canvas_layer_menu = null
	
	# Limpiar captura
	_limpiar_captura()

# ════════════════════════════════════════════════════════════════
# SALIR A MENÚ PRINCIPAL (ESC)
# ════════════════════════════════════════════════════════════════
func salir_como_esc() -> void:
	menu_abierto = false
	print("[MenuSystem] Saliendo a menú principal...")
	
	# Limpiar nodos del menú
	if menu_instancia and is_instance_valid(menu_instancia):
		menu_instancia.queue_free()
		menu_instancia = null
	
	if canvas_layer_menu and is_instance_valid(canvas_layer_menu):
		canvas_layer_menu.queue_free()
		canvas_layer_menu = null
	
	_limpiar_captura()
	await get_tree().process_frame
	get_tree().change_scene_to_file(ESC_TARGET_SCENE)

# ════════════════════════════════════════════════════════════════
# CAPTURAR SCREENSHOT
# ════════════════════════════════════════════════════════════════
func _capturar_screenshot() -> void:
	await get_tree().process_frame
	
	var viewport = get_viewport()
	var imagen = viewport.get_texture().get_image()
	
	if imagen:
		screenshot_imagen = imagen.duplicate()
		print("[MenuSystem] Screenshot capturado en memoria")
	else:
		print("[MenuSystem] Error: No se pudo capturar imagen")

func _limpiar_captura() -> void:
	screenshot_imagen = null
	if FileAccess.file_exists("user://menu_screenshot.png"):
		var err := DirAccess.remove_absolute("user://menu_screenshot.png")
		if err != OK:
			print("[MenuSystem] No se pudo eliminar captura legacy: %d" % err)

# ════════════════════════════════════════════════════════════════
# OBTENER SCREENSHOT
# ════════════════════════════════════════════════════════════════
func obtener_screenshot() -> ImageTexture:
	if screenshot_imagen:
		return ImageTexture.create_from_image(screenshot_imagen)
	return null
