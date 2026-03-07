# SelectorMarchasNuevo.gd - Control de las 4 marchas P/R/N/D
extends Control

signal marcha_cambiada(marcha: String)

@onready var botones = {
	"P": $BotonesMarcha/MarchaP,
	"R": $BotonesMarcha/MarchaR,
	"N": $BotonesMarcha/MarchaN,
	"D": $BotonesMarcha/MarchaD
}

var marcha_actual: String = "N"
var indice_actual: int = 2  # 0=P, 1=R, 2=N, 3=D

func _ready() -> void:
	# 1. Preparar materiales únicos ANTES de conectar nada
	for id in botones:
		var btn = botones[id]
		if btn.material:
			# Forzamos que cada botón tenga su propia copia del shader
			btn.material = btn.material.duplicate()
		
		# 2. Conectar señales
		btn.pressed.connect(_on_marcha_seleccionada.bind(id))
		
		# 3. Estilo de texto inicial
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	# Estado inicial
	_actualizar_visuales()

func _on_marcha_seleccionada(id: String) -> void:
	if marcha_actual == id:
		return
	
	marcha_actual = id
	
	# Mapear a índice numérico
	match id:
		"P": indice_actual = 0
		"R": indice_actual = 1
		"N": indice_actual = 2
		"D": indice_actual = 3
	
	_actualizar_visuales()
	marcha_cambiada.emit(marcha_actual)
	
	# Actualizar el Singleton InputVehiculo si existe
	if is_instance_valid(InputVehiculo):
		if InputVehiculo.has_method("set_marcha_enum"):
			match indice_actual:
				0:
					InputVehiculo.set_marcha_enum(InputVehiculo.Marcha.PARQUEO)
				1:
					InputVehiculo.set_marcha_enum(InputVehiculo.Marcha.REVERSA)
				2:
					InputVehiculo.set_marcha_enum(InputVehiculo.Marcha.NEUTRO)
				3:
					InputVehiculo.set_marcha_enum(InputVehiculo.Marcha.DRIVE)
		elif InputVehiculo.has_method("set_marcha"):
			InputVehiculo.set_marcha(marcha_actual)
	
	# Feedback háptico
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(50)
	
	print("Marcha seleccionada: %s" % id)

func _actualizar_visuales() -> void:
	"""Actualiza el estado visual de todos los botones de forma eficiente"""
	for id in botones:
		var btn = botones[id]
		var es_activa = (id == marcha_actual)
		
		# Actualizar Shader (Solo si el material existe)
		if btn.material:
			btn.material.set_shader_parameter("activo", es_activa)
		
		# Actualizar colores de fuente para resaltar la selección
		var color_texto = Color(1.0, 0.7, 0.1) if es_activa else Color(0.5, 0.5, 0.5)
		btn.add_theme_color_override("font_color", color_texto)
		btn.add_theme_color_override("font_hover_color", color_texto)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)

func set_marcha(idx: int) -> void:
	"""Establecer marcha por índice (0=P, 1=R, 2=N, 3=D)"""
	var nombres = ["P", "R", "N", "D"]
	if idx >= 0 and idx < nombres.size():
		_on_marcha_seleccionada(nombres[idx])

func get_marcha() -> int:
	return indice_actual