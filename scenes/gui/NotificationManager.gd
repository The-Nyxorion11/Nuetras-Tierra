# notification_manager.gd - Sistema de notificaciones flotantes
# NUEVO - Completamente diferente al sistema anterior
extends CanvasLayer

# ════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ════════════════════════════════════════════════════════════════
# const NOTIF_SCENE = preload("res://scenes/gui/Notification.tscn")  # No necesitamos escena precompilada
const DURACION_NOTIF: float = 3.0
const ESPACIO_VERTICAL: float = 100.0

# ════════════════════════════════════════════════════════════════
# VARIABLES
# ════════════════════════════════════════════════════════════════
var _notificaciones_activas: Array[Node] = []

# ════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# ════════════════════════════════════════════════════════════════
# API PÚBLICA - Mostrar notificaciones
# ════════════════════════════════════════════════════════════════

## Mostrar notificación simple
func notificar(mensaje: String, tipo: String = "info", duracion: float = DURACION_NOTIF) -> void:
	_crear_notificacion(mensaje, tipo, duracion)

## Notificación de dinero
func notificar_dinero(cantidad: float, operacion: String = "ganado") -> void:
	var _signo = "+" if cantidad > 0 else ""
	var mensaje = "%s $%.2f" % [operacion.capitalize(), abs(cantidad)]
	var tipo = "ganancia" if cantidad > 0 else "perdida"
	_crear_notificacion(mensaje, tipo, 2.5)

## Notificación de alerta
func notificar_alerta(mensaje: String) -> void:
	_crear_notificacion(mensaje, "alerta", 4.0)

## Notificación de éxito
func notificar_exito(mensaje: String) -> void:
	_crear_notificacion(mensaje, "exito", 2.0)

# ════════════════════════════════════════════════════════════════
# CREACIÓN DE NOTIFICACIÓN
# ════════════════════════════════════════════════════════════════
func _crear_notificacion(mensaje: String, tipo: String, duracion: float) -> void:
	var panel = PanelContainer.new()
	var label = Label.new()
	
	# Configurar label
	label.text = mensaje
	label.custom_minimum_size = Vector2(300, 60)
	label.modulate = Color.WHITE
	
	# Agregar estilos según tipo
	_aplicar_estilo(panel, tipo)
	
	# Ensamblar
	panel.add_child(label)
	add_child(panel)
	
	# Posicionar
	var pos_y = 50 + (_notificaciones_activas.size() * ESPACIO_VERTICAL)
	panel.position = Vector2(get_viewport().get_visible_rect().size.x - 350, pos_y)
	
	# Guardar referencia
	_notificaciones_activas.append(panel)
	
	# Animar entrada
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	panel.modulate.a = 0.0
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	
	# Animar salida tras duracion
	await get_tree().create_timer(duracion).timeout
	
	var tween_out = create_tween()
	tween_out.set_trans(Tween.TRANS_QUAD)
	tween_out.set_ease(Tween.EASE_IN)
	tween_out.tween_property(panel, "modulate:a", 0.0, 0.3)
	await tween_out.finished
	
	# Limpiar
	_notificaciones_activas.erase(panel)
	panel.queue_free()
	
	# Reorganizar otras notificaciones
	_reorganizar_notificaciones()

# ════════════════════════════════════════════════════════════════
# APLICAR ESTILOS SEGÚN TIPO
# ════════════════════════════════════════════════════════════════
func _aplicar_estilo(panel: PanelContainer, tipo: String) -> void:
	var color_bg: Color
	var color_text: Color
	
	match tipo:
		"info":
			color_bg = Color(0.1, 0.4, 0.8, 0.9)  # Azul
			color_text = Color.WHITE
		"exito":
			color_bg = Color(0.2, 0.8, 0.3, 0.9)  # Verde
			color_text = Color.WHITE
		"alerta":
			color_bg = Color(1.0, 0.6, 0.1, 0.9)  # Naranja
			color_text = Color.WHITE
		"ganancia":
			color_bg = Color(0.3, 0.9, 0.4, 0.9)  # Verde brillante
			color_text = Color.WHITE
		"perdida":
			color_bg = Color(0.9, 0.3, 0.3, 0.9)  # Rojo
			color_text = Color.WHITE
		_:
			color_bg = Color(0.5, 0.5, 0.5, 0.9)  # Gris
			color_text = Color.WHITE
	
	# Crear StyleBox
	var style = StyleBoxFlat.new()
	style.bg_color = color_bg
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.set_content_margin_all(12)
	
	# Crear Theme
	var theme = Theme.new()
	theme.set_stylebox("panel", "PanelContainer", style)
	
	# Obtener label hijo
	if panel.get_child_count() > 0:
		var label = panel.get_child(0)
		label.add_theme_color_override("font_color", color_text)
		label.add_theme_font_size_override("font_size", 16)
	
	panel.theme = theme

# ════════════════════════════════════════════════════════════════
# REORGANIZAR NOTIFICACIONES AL ELIMINAR UNA
# ════════════════════════════════════════════════════════════════
func _reorganizar_notificaciones() -> void:
	for i in range(_notificaciones_activas.size()):
		var notif = _notificaciones_activas[i]
		var pos_y = 50 + (i * ESPACIO_VERTICAL)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(notif, "position:y", pos_y, 0.3)
