# InputVehiculo.gd
# Autoload para gestionar todas las entradas del vehículo de forma centralizada
extends Node

# Estados del motor
var motor_encendido: bool = false
var velocidad_motor: float = 0.0

# Entrada analógica
var gas: float = 0.0
var freno: float = 0.0
var freno_mano: bool = false
var direccion: float = 0.0

# Estado de marchas
enum Marcha { PARQUEO, REVERSA, NEUTRO, DRIVE }
var marcha_actual: Marcha = Marcha.PARQUEO
var marcha: String = "P"

# Centro de control activo
var en_control: bool = false

func _ready() -> void:
	print("[Input] InputVehiculo iniciado")

func _process(delta: float) -> void:
	if not en_control:
		return
	
	_leer_entrada(delta)

func _leer_entrada(delta: float) -> void:
	# Gas/Aceleracion
	if Input.is_action_pressed("gas"):
		gas = move_toward(gas, 1.0, delta * 2.0)
	else:
		gas = move_toward(gas, 0.0, delta * 3.0)
	
	# Freno
	if Input.is_action_pressed("freno"):
		freno = move_toward(freno, 1.0, delta * 2.0)
	else:
		freno = move_toward(freno, 0.0, delta * 3.0)
	
	# Freno mano
	freno_mano = Input.is_action_pressed("freno_mano")
	
	# Direccion
	var dir_input: float = 0.0
	if Input.is_action_pressed("girar_izquierda"):
		dir_input -= 1.0
	if Input.is_action_pressed("girar_derecha"):
		dir_input += 1.0
	
	direccion = move_toward(direccion, dir_input, delta * 3.0)
	
	# Cambio de marchas
	if Input.is_action_just_pressed("marcha_parqueo"):
		establecer_marcha(Marcha.PARQUEO)
	if Input.is_action_just_pressed("marcha_reversa"):
		establecer_marcha(Marcha.REVERSA)
	if Input.is_action_just_pressed("marcha_neutro"):
		establecer_marcha(Marcha.NEUTRO)
	if Input.is_action_just_pressed("marcha_drive"):
		establecer_marcha(Marcha.DRIVE)
	
	# Encender/Apagar motor
	if Input.is_action_just_pressed("encender_motor"):
		motor_encendido = !motor_encendido

func establecer_marcha(nueva_marcha: Marcha) -> void:
	marcha_actual = nueva_marcha
	match nueva_marcha:
		Marcha.PARQUEO:
			marcha = "P"
		Marcha.REVERSA:
			marcha = "R"
		Marcha.NEUTRO:
			marcha = "N"
		Marcha.DRIVE:
			marcha = "D"
	print("[Input] Marcha: ", marcha)

# API publica para compatibilidad con UI tactil/PC
func set_gas(v: float) -> void:
	gas = clamp(v, 0.0, 1.0)

func set_freno(v: float) -> void:
	freno = clamp(v, 0.0, 1.0)

func set_dir(v: float) -> void:
	direccion = clamp(v, -1.0, 1.0)

func set_direccion(v: float) -> void:
	set_dir(v)

func centrar_direccion() -> void:
	direccion = 0.0

func set_fmano(estado: bool) -> void:
	freno_mano = estado

func set_motor_encendido(estado: bool) -> void:
	motor_encendido = estado

func set_marcha_enum(nueva_marcha: Marcha) -> void:
	establecer_marcha(nueva_marcha)

func set_marcha(nueva_marcha: String) -> void:
	match nueva_marcha:
		"P":
			establecer_marcha(Marcha.PARQUEO)
		"R":
			establecer_marcha(Marcha.REVERSA)
		"N":
			establecer_marcha(Marcha.NEUTRO)
		"D":
			establecer_marcha(Marcha.DRIVE)

func reset_tactil() -> void:
	gas = 0.0
	freno = 0.0
	direccion = 0.0
	freno_mano = false

func esta_en_reversa() -> bool:
	return marcha_actual == Marcha.REVERSA

func esta_en_drive() -> bool:
	return marcha_actual == Marcha.DRIVE

func start_driving() -> void:
	en_control = true
	print("[Input] Control del vehiculo activado")

func stop_driving() -> void:
	en_control = false
	gas = 0.0
	freno = 0.0
	direccion = 0.0
	print("[Input] Control del vehiculo desactivado")

func resetear() -> void:
	gas = 0.0
	freno = 0.0
	freno_mano = false
	direccion = 0.0
	motor_encendido = false
	marcha_actual = Marcha.PARQUEO
	print("[Input] InputVehiculo resetado")
