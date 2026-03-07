extends Node3D

@export_group("Suspensión Visual")
@export var rigidez: float = 10.0      # Qué tan "duro" es el balanceo visual
@export var amortiguacion: float = 4.0 # Qué tan rápido deja de oscilar
@export var inclinacion_max_pitch: float = 0.05
@export var inclinacion_max_roll: float  = 0.06

@export_group("Vibración Motor")
@export var vibe_ralenti: float = 0.001
@export var vibe_carga: float   = 0.003
@export var freq_diesel: float  = 20.0

var _coche: RigidBody3D
var _pos_original: Vector3
var _time: float = 0.0
var _rot_actual: Vector3 = Vector3.ZERO
var _rot_vel: Vector3    = Vector3.ZERO

var _vel_local_prev: Vector3 = Vector3.ZERO

func _ready() -> void:
	_coche = get_parent() as RigidBody3D
	_pos_original = position

func _physics_process(delta: float) -> void:
	if not _coche or _coche.freeze: return
	_time += delta

	# Obtener datos locales del coche
	var inv_basis    = _coche.global_transform.basis.inverse()
	var vel_local    = inv_basis * _coche.linear_velocity
	var vel_adelante = vel_local.z
	var acel_local   = (vel_local - _vel_local_prev) / max(delta, 0.001)
	_vel_local_prev  = vel_local
	var ang_vel_local = inv_basis * _coche.angular_velocity

	# 1. PITCH (Inclinación al acelerar/frenar)
	# Al acelerar (adelante) se levanta el frente, al frenar se hunde.
	var target_pitch = -acel_local.z * 0.004
	target_pitch = clamp(target_pitch, -inclinacion_max_pitch, inclinacion_max_pitch)

	# 2. ROLL (Inclinación al girar - Opuesta al giro)
	var factor_vel = clamp(abs(vel_adelante) / 20.0, 0.0, 1.0)
	# Se inclina hacia el exterior de la curva.
	var target_roll = -ang_vel_local.y * -vel_adelante * 0.01 * factor_vel
	target_roll = clamp(target_roll, -inclinacion_max_roll, inclinacion_max_roll)

	# 3. SISTEMA PD (Suavizado de la rotación)
	var rot_objetivo = Vector3(target_pitch, 0.0, target_roll)
	var error  = rot_objetivo - _rot_actual
	var fuerza = (error * rigidez) - (_rot_vel * amortiguacion * 8.0)
	_rot_vel   += fuerza * delta
	_rot_actual += _rot_vel * delta

	# 4. VIBRACIÓN DIESEL
	var input_gas = InputVehiculo.gas if is_instance_valid(InputVehiculo) else 0.0
	var vibe_amp = lerp(vibe_ralenti, vibe_carga, input_gas)
	var vibe_x   = sin(_time * freq_diesel) * vibe_amp

	# APLICAR A LA MALLA
	rotation.x = _rot_actual.x + vibe_x
	rotation.z = _rot_actual.z
