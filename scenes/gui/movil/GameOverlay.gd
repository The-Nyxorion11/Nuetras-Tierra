# game_overlay.gd - Sistema de overlay/menú moderno
# Completamente nuevo - elegante, rápido y funcional
extends CanvasLayer

# ════════════════════════════════════════════════════════════════
# PANTALLAS
# ════════════════════════════════════════════════════════════════
enum PANTALLA { PRINCIPAL, MAPA, OPCIONES, INVENTARIO }

# ════════════════════════════════════════════════════════════════
# REFERENCIAS A NODOS
# ════════════════════════════════════════════════════════════════
@onready var fondo_oscuro: ColorRect = $FondoOscuro
@onready var panel_menu: Control = $PanelMenu

# Botones principales
@onready var btn_mapa: Button = $PanelMenu/PanelContainer/MarginContainer/VBoxContainer/GridBotones/BtnMapa
@onready var btn_opciones: Button = $PanelMenu/PanelContainer/MarginContainer/VBoxContainer/GridBotones/BtnOpciones
@onready var btn_inventario: Button = $PanelMenu/PanelContainer/MarginContainer/VBoxContainer/GridBotones/BtnInventario
@onready var btn_cerrar: Button = $PanelMenu/PanelContainer/MarginContainer/VBoxContainer/GridBotones/BtnCerrar

# Displays
@onready var lbl_dinero: Label = $PanelMenu/PanelContainer/MarginContainer/VBoxContainer/LabelDinero
@onready var lbl_hora: Label = $PanelMenu/PanelContainer/MarginContainer/VBoxContainer/LabelHora

# ════════════════════════════════════════════════════════════════
# ESTADO
# ════════════════════════════════════════════════════════════════
var abierto: bool = false
var pantalla_actual: PANTALLA = PANTALLA.PRINCIPAL

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# Configurar fondo oscuro
	if fondo_oscuro:
		fondo_oscuro.color = Color(0, 0, 0, 0.7)
		fondo_oscuro.gui_input.connect(_on_fondo_input)
	
	# Conectar botones
	_conectar_botones()
	
	# Conectar a GameManager
	if GameManager:
		GameManager.pantalla_abierta.connect(_on_pantalla_abierta)
		GameManager.pantalla_cerrada.connect(_on_pantalla_cerrada)
		GameManager.dinero_actualizado.connect(_on_dinero_actualizado)

# ════════════════════════════════════════════════════════════════
# CONECTAR BOTONES
# ════════════════════════════════════════════════════════════════
func _conectar_botones() -> void:
	if btn_mapa:
		btn_mapa.pressed.connect(func(): _cambiar_pantalla(PANTALLA.MAPA))
	
	if btn_opciones:
		btn_opciones.pressed.connect(func(): _cambiar_pantalla(PANTALLA.OPCIONES))
	
	if btn_inventario:
		btn_inventario.pressed.connect(func(): _cambiar_pantalla(PANTALLA.INVENTARIO))
	
	if btn_cerrar:
		btn_cerrar.pressed.connect(_cerrar_overlay)

# ════════════════════════════════════════════════════════════════
# ABRIR/CERRAR OVERLAY
# ════════════════════════════════════════════════════════════════
func _on_pantalla_abierta(nombre: String) -> void:
	if nombre == "menu_principal":
		_abrir_overlay()

func _on_pantalla_cerrada(_nombre: String) -> void:
	_cerrar_overlay()

func _abrir_overlay() -> void:
	abierto = true
	visible = true
	
	if panel_menu:
		panel_menu.scale = Vector2(0.7, 0.7)
		panel_menu.modulate.a = 0.0
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_parallel(true)
		tween.tween_property(panel_menu, "scale", Vector2(1.0, 1.0), 0.4)
		tween.tween_property(panel_menu, "modulate:a", 1.0, 0.3)

func _cerrar_overlay() -> void:
	abierto = false
	
	if panel_menu:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_IN)
		tween.set_parallel(true)
		tween.tween_property(panel_menu, "scale", Vector2(0.7, 0.7), 0.3)
		tween.tween_property(panel_menu, "modulate:a", 0.0, 0.3)
		await tween.finished
	
	visible = false

# ════════════════════════════════════════════════════════════════
# CAMBIAR PANTALLAS
# ════════════════════════════════════════════════════════════════
func _cambiar_pantalla(tipo: PANTALLA) -> void:
	pantalla_actual = tipo
	match tipo:
		PANTALLA.MAPA:
			print("[Overlay] Abriendo mapa...")
		PANTALLA.OPCIONES:
			print("[Overlay] Abriendo opciones...")
		PANTALLA.INVENTARIO:
			print("[Overlay] Abriendo inventario...")

# ════════════════════════════════════════════════════════════════
# ACTUALIZAR INFORMACIÓN
# ════════════════════════════════════════════════════════════════
func _process(_delta: float) -> void:
	if not visible or not abierto:
		return
	
	if lbl_dinero:
		var dinero = GameManager.obtener_dinero()
		lbl_dinero.text = "Dinero: $%.2f" % dinero
	
	if lbl_hora:
		var hora = GameManager.obtener_hora_formateada(0.5)  # Hora simulada
		lbl_hora.text = "Hora: " + hora

func _on_dinero_actualizado(nuevo_dinero: float) -> void:
	if lbl_dinero and abierto:
		lbl_dinero.text = "Dinero: $%.2f" % nuevo_dinero

# ════════════════════════════════════════════════════════════════
# INPUT HANDLING
# ════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if not abierto:
		return
	
	# Cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		_cerrar_overlay()
		GameManager.cerrar_pantalla()
		get_tree().root.set_input_as_handled()

func _on_fondo_input(event: InputEvent) -> void:
	# Cerrar al clickear el fondo
	if event is InputEventMouseButton and event.pressed:
		if abierto:
			_cerrar_overlay()
			GameManager.cerrar_pantalla()
			get_tree().root.set_input_as_handled()
