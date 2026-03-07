# game_manager.gd - Controlador global del juego (Refactorizado)
extends Node

signal dinero_actualizado(nuevo_monto: float)
signal camara_cambiada(nueva_id: int)
signal pantalla_abierta(nombre: String)
signal pantalla_cerrada(nombre: String)

# ════════════════════════════════════════════════════════════════
# VARIABLES GLOBALES DEL JUEGO
# ════════════════════════════════════════════════════════════════
var dinero: float = 2500.0
var indice_camara: int = 0
var total_camaras: int = 3

# Referencias a UI
var ui_overlay: Control = null
var pantalla_actual: String = "juego"
var pausa_activa: bool = false

# ════════════════════════════════════════════════════════════════
func _ready() -> void:
	print("[GameManager] Sistema inicializado")

# ════════════════════════════════════════════════════════════════
# DINERO - API FINANCIERA
# ════════════════════════════════════════════════════════════════
func modificar_dinero(cantidad: float) -> void:
	dinero = clamp(dinero + cantidad, 0, 999999)
	dinero_actualizado.emit(dinero)

func obtener_dinero() -> float:
	return dinero

# ════════════════════════════════════════════════════════════════
# CÁMARAS
# ════════════════════════════════════════════════════════════════
func cambiar_camara_global() -> void:
	indice_camara = (indice_camara + 1) % total_camaras
	camara_cambiada.emit(indice_camara)

# ════════════════════════════════════════════════════════════════
# PANTALLAS Y MENÚS
# ════════════════════════════════════════════════════════════════
func abrir_pantalla(nombre: String) -> void:
	pantalla_actual = nombre
	pausa_activa = true
	get_tree().paused = true
	pantalla_abierta.emit(nombre)

func cerrar_pantalla() -> void:
	pantalla_actual = "juego"
	pausa_activa = false
	get_tree().paused = false
	pantalla_cerrada.emit("")

# ════════════════════════════════════════════════════════════════
# UTILIDADES
# ════════════════════════════════════════════════════════════════
func obtener_hora_formateada(tiempo: float) -> String:
	var total_minutos = int(tiempo * 1440)
	var horas = int(total_minutos / 60.0)
	var minutos = total_minutos % 60
	return "%02d:%02d" % [horas, minutos]
