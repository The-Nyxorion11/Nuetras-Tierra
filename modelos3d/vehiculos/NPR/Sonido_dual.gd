# sonido_dual.gd
extends Node3D

@export var config: Resource = null

@onready var idle_player: AudioStreamPlayer3D = $SonidoIdle
@onready var power_player: AudioStreamPlayer3D = $SonidoAcelerar

# Variables de interpolación para suavidad
var pitch_actual: float = 0.5

func _ready() -> void:
	# Pequeña espera para asegurar que el motor de audio esté listo
	await get_tree().create_timer(0.1).timeout
	
	if idle_player:
		idle_player.unit_size = 10.0 # Alcance del sonido
		idle_player.play()
	if power_player:
		power_player.unit_size = 12.0
		power_player.play()

func procesar_audio(rpm_norm: float, gas: float, delta: float) -> void:
	if not idle_player or not power_player:
		return
	
	if not config:
		return
	
	# Si el motor está apagado, silenciar completamente
	if not is_instance_valid(InputVehiculo) or not InputVehiculo.motor_encendido:
		idle_player.volume_db = -80.0
		power_player.volume_db = -80.0
		return

	# Asegurar que los sonidos estén activos (Godot puede mutearlos si están lejos)
	if not idle_player.playing:
		idle_player.play()
	if not power_player.playing:
		power_player.play()

	# 1. CÁLCULO DE PITCH (RPM)
	# El pitch responde a las RPM normalizadas (0.0 a 1.0)
	var pitch_target = lerp(config.pitch_min, config.pitch_max, rpm_norm)
	
	# Inercia: el motor sube de vueltas más rápido de lo que baja
	var factor_inercia = config.suavizado_subida if pitch_target > pitch_actual else config.suavizado_bajada
	pitch_actual = lerp(pitch_actual, pitch_target, delta * factor_inercia)
	
	idle_player.pitch_scale = clamp(pitch_actual, 0.1, 4.0)
	power_player.pitch_scale = clamp(pitch_actual, 0.1, 4.0)

	# 2. CROSSFADE DE VOLUMEN (Mezcla de capas)
	# El 'gas' (0 a 1) controla qué capa predomina
	var factor_mezcla = smoothstep(0.0, 1.0, gas)
	
	# IDLE: Baja un poco el volumen cuando el motor está bajo carga para dejar oir el rugido
	var vol_idle = lerp(0.0, -8.0, factor_mezcla)
	# POWER: De -40dB (silencio casi total) a 2dB (fuerza total)
	var vol_power = lerp(-40.0, 2.0, factor_mezcla)

	# Aplicar con lerp para evitar 'pops' de audio
	idle_player.volume_db = lerp(idle_player.volume_db, vol_idle, delta * 6.0)
	power_player.volume_db = lerp(power_player.volume_db, vol_power, delta * 10.0)

	# 3. EFECTO LIMITADOR (Corte de inyección)
	if rpm_norm > 0.97:
		# Crea un tartamudeo rápido en el volumen
		var vibrato = sin(Time.get_ticks_msec() * 0.05) * 5.0
		power_player.volume_db += vibrato
