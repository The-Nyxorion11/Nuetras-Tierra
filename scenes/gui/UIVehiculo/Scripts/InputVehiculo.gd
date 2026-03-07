# input_vehiculo.gd - Sistema robusto de input para vehículos en móviles y PC
# Autor: Johan
# Maneja: aceleración, frenado, dirección, freno de mano, marchas y motor
extends Node

# ════════════════════════════════════════════════════════════════════════════
# VARIABLES DE CONDUCCIÓN EN TIEMPO REAL
# ════════════════════════════════════════════════════════════════════════════
var conduciendo: bool = false
var gas: float = 0.0
var freno: float = 0.0
var direccion: float = 0.0
var freno_mano: bool = false
var motor_encendido: bool = false
var marcha: String = "N"
enum Marcha { PARQUEO, REVERSA, NEUTRO, DRIVE }
var marcha_actual: Marcha = Marcha.NEUTRO

# ════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE SUAVIZADO
# ════════════════════════════════════════════════════════════════════════════
@export var suavizado_direccion: float = 10.0
@export var suavizado_pedales: float = 12.0

# ════════════════════════════════════════════════════════════════════════════
# VARIABLES INTERNAS DE SUAVIZADO
# ════════════════════════════════════════════════════════════════════════════
var _gas_target: float = 0.0
var _freno_target: float = 0.0
var _dir_target: float = 0.0

# ════════════════════════════════════════════════════════════════════════════
# MULTIPLICADORES DE TRANSMISIÓN
# ════════════════════════════════════════════════════════════════════════════
var multiplicador_rango: bool = false
var multiplicador_splitter: bool = false

# ════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ════════════════════════════════════════════════════════════════════════════
const MARCHAS_DISPLAY := ["P", "R", "N", "D"]

# ════════════════════════════════════════════════════════════════════════════
# CICLO DE PROCESAMIENTO
# ════════════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if not conduciendo:
		_reset_inputs_instant()
		return
	
	# Tecla de encendido/apagado (solo en PC/Editor)
	if Input.is_action_just_pressed("encender_motor"):
		motor_encendido = not motor_encendido
	
	_procesar_entradas_raw()
	_aplicar_suavizado(delta)

# ════════════════════════════════════════════════════════════════════════════
# PROCESAMIENTO DE ENTRADAS RAW (Teclado/Joystick PC)
# ════════════════════════════════════════════════════════════════════════════
func _procesar_entradas_raw() -> void:
	# Dirección: izquierda negativo, derecha positivo
	var dir_keyboard = Input.get_axis("izquierda", "derecha")
	
	# Solo aplicar input de teclado si hay input real
	if abs(dir_keyboard) > 0.05:
		_dir_target = dir_keyboard
	# NO resetear automáticamente - mantener posición del volante
	
	# Gas - máximo entre teclado y táctil
	var gas_input = Input.get_action_strength("acelerar")
	_gas_target = max(gas_input, _gas_target)
	
	# Freno - máximo entre teclado y táctil
	var freno_input = Input.get_action_strength("frenar")
	_freno_target = max(freno_input, _freno_target)
	
	# Freno de mano - cualquier entrada táctil o teclado
	freno_mano = Input.is_action_pressed("freno_mano")

# ════════════════════════════════════════════════════════════════════════════
# APLICAR SUAVIZADO A LOS VALORES
# ════════════════════════════════════════════════════════════════════════════
func _aplicar_suavizado(delta: float) -> void:
	# Interpolación suave para dirección
	direccion = lerp(direccion, _dir_target, suavizado_direccion * delta)
	
	# Interpolación suave para acelerador y freno
	gas   = lerp(gas,   _gas_target,   suavizado_pedales * delta)
	freno = lerp(freno, _freno_target, suavizado_pedales * delta)
	
	# Decaimiento gradual cuando se suelta
	_gas_target   = move_toward(_gas_target,   0.0, delta * 0.5)
	_freno_target = move_toward(_freno_target, 0.0, delta * 0.5)
	# AUTO-CENTRADO DEL VOLANTE: vuelve al centro gradualmente
	_dir_target   = move_toward(_dir_target,   0.0, delta * 2.5)

# ════════════════════════════════════════════════════════════════════════════
# API PÚBLICA - CONTROLES TÁCTILES (MÓVIL)
# ════════════════════════════════════════════════════════════════════════════

## Establece la dirección desde joystick táctil (-1.0 a 1.0)
func set_dir(v: float) -> void:
	_dir_target = clamp(v, -1.0, 1.0)

## Establece la dirección desde volante (alias para compatibilidad)
func set_direccion(v: float) -> void:
	_dir_target = clamp(v, -1.0, 1.0)

## Establece el gas desde botón táctil (0.0 a 1.0)
func set_gas(v: float) -> void:
	_gas_target = clamp(v, 0.0, 1.0)

## Establece el freno desde botón táctil (0.0 a 1.0)
func set_freno(v: float) -> void:
	_freno_target = clamp(v, 0.0, 1.0)

## Establece el freno de mano (desde botón táctil)
func set_fmano(estado: bool) -> void:
	freno_mano = estado

## Centra la dirección (volver a 0)
func centrar_direccion() -> void:
	_dir_target = 0.0
	direccion = 0.0

## Cambia la marcha actual por índice del enum
func set_marcha_enum(nueva: Marcha) -> void:
	marcha_actual = nueva
	marcha = MARCHAS_DISPLAY[nueva]

## Cambia la marcha actual por string (P/R/N/D)
func set_marcha(nueva_marcha: String) -> void:
	var idx = MARCHAS_DISPLAY.find(nueva_marcha)
	if idx >= 0:
		marcha_actual = idx as Marcha
		marcha = nueva_marcha

## Obtiene la marcha actual como string
func get_marcha() -> String:
	return marcha

## Obtiene el enum de marcha actual
func get_marcha_enum() -> Marcha:
	return marcha_actual

## Verifica si está en Drive
func esta_en_drive() -> bool:
	return marcha_actual == Marcha.DRIVE

## Verifica si está en Reversa
func esta_en_reversa() -> bool:
	return marcha_actual == Marcha.REVERSA

## Verifica si puede moverse (no está en P o N)
func puede_moverse() -> bool:
	return marcha_actual == Marcha.DRIVE or marcha_actual == Marcha.REVERSA

## Enciende/apaga el motor
func set_motor_encendido(estado: bool) -> void:
	motor_encendido = estado

## Resetea todos los inputs de forma instantánea
func _reset_inputs_instant() -> void:
	gas           = 0.0
	freno         = 0.0
	direccion     = 0.0
	_gas_target   = 0.0
	_freno_target = 0.0
	_dir_target   = 0.0
	freno_mano    = false
	# No resetear motor_encendido aquí, solo pedales y dirección

## Resetea inputs táctiles específicamente (para cuando se pierde el foco)
func reset_tactil() -> void:
	_reset_inputs_instant()
	# Mantener estado del motor

## Comienza la conducción
func start_driving() -> void:
	conduciendo = true
	marcha = "N"
	marcha_actual = Marcha.NEUTRO as Marcha

## Detiene la conducción y resetea todo
func stop_driving() -> void:
	conduciendo = false
	motor_encendido = false
	_reset_inputs_instant()
