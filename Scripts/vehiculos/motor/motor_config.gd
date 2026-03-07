# motor_config.gd
extends Resource
class_name MotorConfig

@export_group("Motor Diésel")
@export var par_maximo: float = 2800.0
@export var rpm_par_maximo: float = 1200.0
@export var rpm_minimas: float = 650.0
@export var rpm_maximas: float = 2200.0
@export var inercia_motor: float = 0.8
@export var aceleracion_rpm_max: float = 2000.0

@export_group("Frenado")
@export var inercia_freno: float = 0.3  # Tiempo de suavizado del freno en segundos (más bajo que motor)

@export_group("Transmisión")
@export var relaciones_caja: Array[float] = [14.0, 10.0, 7.5, 5.8, 4.5, 3.2, 2.5, 1.8, 1.3, 1.0]
@export var relacion_diferencial: float = 3.8
@export var radio_rueda: float = 0.5
@export var eficiencia_transmision: float = 0.9
@export var velocidad_maxima_kmh: float = 95.0

@export_group("Cambio Automático")
@export var rpm_subir_marcha: float = 1800.0
@export var rpm_bajar_marcha: float = 1100.0

func get_factor_par(rpm: float) -> float:
	if rpm < rpm_minimas:
		return 0.2
	if rpm > rpm_maximas:
		return 0.0

	var t: float = (rpm - rpm_minimas) / (rpm_maximas - rpm_minimas)
	var pico_norm: float = (rpm_par_maximo - rpm_minimas) / (rpm_maximas - rpm_minimas)

	if t <= pico_norm:
		return lerp(0.5, 1.0, pow(t / max(pico_norm, 0.01), 0.5))
	else:
		return lerp(1.0, 0.4, (t - pico_norm) / max(1.0 - pico_norm, 0.01))
