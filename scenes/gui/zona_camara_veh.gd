# zona_camara_vehiculo.gd
extends Control

signal camara_movida(relative_vector)

var toques_activos: Dictionary = {}
var mouse_presionado: bool = false
var brazo_camara: Node3D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	_buscar_brazo()

func _buscar_brazo() -> void:
	# Subir por el árbol hasta encontrar el vehículo
	var p = get_parent()
	while p != null:
		if p.is_in_group("vehiculo"):
			brazo_camara = p.get_node_or_null("BrazoCamara")
			break
		p = p.get_parent()

	if brazo_camara:
		if not camara_movida.is_connected(brazo_camara.rotar_tactil):
			camara_movida.connect(brazo_camara.rotar_tactil)
		print("ZonaCamara vehiculo conectada a BrazoCamara OK")
	else:
		push_warning("ZonaCamara vehiculo: BrazoCamara no encontrado")

func _input(event: InputEvent) -> void:
	# --- MOUSE ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if get_global_rect().has_point(event.position):
					mouse_presionado = true
					get_viewport().set_input_as_handled()
			else:
				mouse_presionado = false

	elif event is InputEventMouseMotion and mouse_presionado:
		emit_signal("camara_movida", event.relative)
		_crear_efecto(event.position - global_position)
		get_viewport().set_input_as_handled()

	# --- TÁCTIL ---
	elif event is InputEventScreenTouch:
		if event.pressed:
			if get_global_rect().has_point(event.position):
				toques_activos[event.index] = event.position
				get_viewport().set_input_as_handled()
		else:
			if toques_activos.has(event.index):
				toques_activos.erase(event.index)
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if toques_activos.has(event.index):
			toques_activos[event.index] = event.position
			emit_signal("camara_movida", event.relative)
			_crear_efecto(event.position - global_position)
			get_viewport().set_input_as_handled()

func _crear_efecto(pos_local: Vector2) -> void:
	var ripple = TouchRipple.new(pos_local)
	add_child(ripple)

# ════════════════════════════════════════════════════════════════════
#  TouchRipple
# ════════════════════════════════════════════════════════════════════

class TouchRipple extends Node2D:
	var lifetime: float = 0.0
	var max_life: float = 0.45

	func _init(pos: Vector2) -> void:
		position = pos

	func _process(delta: float) -> void:
		lifetime += delta
		if lifetime >= max_life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var t: float = lifetime / max_life
		var ease_t: float = 1.0 - pow(1.0 - t, 3)
		var radio_ext: float = lerp(8.0, 38.0, ease_t)
		var alpha_ext: float = lerp(0.35, 0.0, ease_t)
		draw_arc(Vector2.ZERO, radio_ext, 0, TAU, 32,
			Color(1.0, 1.0, 1.0, alpha_ext), 1.2, true)
		var largo: float = lerp(5.0, 10.0, ease_t)
		var alpha_cruz: float = lerp(0.5, 0.0, ease_t)
		draw_line(Vector2(-largo, 0), Vector2(largo, 0), Color(1.0, 1.0, 1.0, alpha_cruz), 0.8)
		draw_line(Vector2(0, -largo), Vector2(0, largo), Color(1.0, 1.0, 1.0, alpha_cruz), 0.8)
		var alpha_dot: float = max(lerp(0.6, 0.0, ease_t) * (1.0 - ease_t * 2.0), 0.0)
		draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 1.0, alpha_dot))
