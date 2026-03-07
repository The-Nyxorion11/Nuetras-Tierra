extends DirectionalLight3D

@export_group("Configuración de Tiempo")
@export var velocidad_tiempo: float = 0.05  # Cuánto avanza el tiempo
@export var tiempo_actual: float = 0.25    # 0.0 a 1.0 (0.25 es mediodía)
@export var pausar_tiempo: bool = false

@export_group("Ajustes de Luz")
@export var energia_max_sol: float = 1.2
@export var energia_noche_luna: float = 0.1
@export var color_noche: Color = Color(0.15, 0.2, 0.3)
@export var color_dia: Color = Color(1.0, 0.95, 0.85)

func _process(delta: float) -> void:
	if not pausar_tiempo:
		# Avanzar el reloj
		tiempo_actual += delta * velocidad_tiempo
		if tiempo_actual > 1.0:
			tiempo_actual = 0.0
	
	actualizar_ciclo()

func actualizar_ciclo():
	# 1. Rotar el sol (Eje X maneja la altura del sol)
	# Multiplicamos por 360 grados y restamos 90 para que 0.25 sea el cenit
	var angulo_x = (tiempo_actual * 360.0) - 90.0
	rotation_degrees.x = angulo_x
	rotation_degrees.y = 45.0 # Ángulo constante para que no salga siempre del mismo punto
	
	# 2. Calcular factores de intensidad
	# Usamos el dot product de la dirección hacia abajo para saber si es noche
	var sun_dir = -get_global_transform().basis.z
	var factor_luz = clamp(sun_dir.y, 0.0, 1.0)
	
	# 3. Ajustar energía y color de la luz direccional
	light_energy = lerp(energia_noche_luna, energia_max_sol, factor_luz)
	light_color = color_noche.lerp(color_dia, factor_luz)
	
	# 4. Sombras: desactivarlas de noche ahorra mucho rendimiento en móvil
	shadow_enabled = factor_luz > 0.1
