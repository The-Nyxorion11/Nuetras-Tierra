@tool
# coche.gd
extends RigidBody3D

@export_group("Componentes")
@onready var motor = $Motor
@onready var llantas_controlador = $ControladorLlantas
@onready var ui_vehiculo = $UIVehiculo
@onready var chasis_visual = $Cuerpo2/Plane

@export_group("Skins")
@export var carpeta_skins: String = "res://modelos3d/vehiculos/Buses/MarcopoloG8-1200/skins":
	set(value):
		carpeta_skins = value
		_refrescar_skins_disponibles()
		if Engine.is_editor_hint():
			notify_property_list_changed()
@export_node_path("MeshInstance3D") var nodo_skin_mesh_path: NodePath = ^"Cuerpo2/Plane"
@export var superficie_skin: int = 0
@export var aplicar_skin_al_iniciar: bool = false
@export var parametro_shader_skin: StringName = &"albedo_texture"

# Cámaras hardcodeadas según tu árbol de escena
@onready var cam_externa  = $Cams_pivot/Cam_Externa
@onready var cam_interna  = $AsientoConductor/Cam_Interna
@onready var cam_brazo    = $BrazoCamara/SpringArm3D/Camera3D
@onready var brazo_camara = $BrazoCamara
@onready var spring_arm   = $BrazoCamara/SpringArm3D

@export_group("Física")
@export var masa_kg: float = 2500.0  # Reducido de 8500 a 2500kg
@export var centro_de_masa: Vector3 = Vector3(0, -0.3, 0.2)  # Más bajo y centrado
@export var estabilizacion_trasera: float = 0.8
@export var arrastre_cuadratico: float = 0.8
@export var velocidad_min_arrastre: float = 1.0
@export var umbral_enderezado: float = 0.7
@export var torque_enderezado: float = 50000.0
@export var umbral_deslizamiento_lateral: float = 0.1
@export var velocidad_min_estabilizacion: float = 0.5
@export var brazo_estabilizacion_trasera: float = 2.0
@export var salida_offset_lateral_desde_zona: float = 1.25
@export var salida_offset_vertical: float = 0.15

var activo: bool = false
var jugador_ref: Node3D = null
var jugador_cerca: bool = false
var nivel_suciedad: float = 0.0
var nivel_barro: float = 0.0
var nivel_mojado: float = 0.0
var indice_camara: int = 0
var skins_disponibles: PackedStringArray = []
var skin_actual: String = ""
var skin_inicial: String = ""

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_refrescar_skins_disponibles()
		notify_property_list_changed()

func _ready() -> void:
	if Engine.is_editor_hint():
		_refrescar_skins_disponibles()
		return

	add_to_group("vehiculo")
	mass = masa_kg

	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = centro_de_masa

	freeze = true

	if ui_vehiculo:
		ui_vehiculo.visible = false

	_alternar_sistemas(false)
	_conectar_deteccion()

	# Conectar señal del GameManager
	GameManager.camara_cambiada.connect(_al_cambiar_camara)

	if chasis_visual:
		chasis_visual.set_instance_shader_parameter("dirt_amount", 0.0)
		chasis_visual.set_instance_shader_parameter("mud_amount",  0.0)
		chasis_visual.set_instance_shader_parameter("wet_amount",  0.0)

	_refrescar_skins_disponibles()
	if aplicar_skin_al_iniciar and not skin_inicial.is_empty():
		aplicar_skin(skin_inicial)

func _get_property_list() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var opciones: PackedStringArray = ["<ninguna>"]

	for skin in skins_disponibles:
		opciones.append(skin)

	lista.append({
		"name": "skin_inicial",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(opciones),
		"usage": PROPERTY_USAGE_DEFAULT
	})

	return lista

func _get(property: StringName) -> Variant:
	if property == &"skin_inicial":
		return "<ninguna>" if skin_inicial.is_empty() else skin_inicial
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == &"skin_inicial":
		var seleccionado := String(value)
		skin_inicial = "" if seleccionado == "<ninguna>" else seleccionado
		return true
	return false

# ════════════════════════════════════════════════════════════════════
#  SKINS
# ════════════════════════════════════════════════════════════════════

func _refrescar_skins_disponibles() -> void:
	skins_disponibles.clear()

	var dir := DirAccess.open(carpeta_skins)
	if dir == null:
		push_warning("coche.gd: no se pudo abrir carpeta de skins: %s" % carpeta_skins)
		return

	dir.list_dir_begin()
	var nombre := dir.get_next()
	while not nombre.is_empty():
		if not dir.current_is_dir():
			var ext := nombre.get_extension().to_lower()
			if ext in ["png", "jpg", "jpeg", "webp"]:
				skins_disponibles.append(nombre)
		nombre = dir.get_next()
	dir.list_dir_end()

	skins_disponibles.sort()

func obtener_skins_disponibles() -> PackedStringArray:
	return skins_disponibles.duplicate()

func aplicar_skin_por_indice(indice: int) -> bool:
	if indice < 0 or indice >= skins_disponibles.size():
		return false
	return aplicar_skin(skins_disponibles[indice])

func aplicar_skin(nombre_archivo: String) -> bool:
	if nombre_archivo.is_empty():
		return false

	var ruta_skin := carpeta_skins.path_join(nombre_archivo)
	if not ResourceLoader.exists(ruta_skin):
		push_warning("coche.gd: skin no encontrada: %s" % ruta_skin)
		return false

	var textura := load(ruta_skin)
	if not (textura is Texture2D):
		push_warning("coche.gd: recurso no valido como textura: %s" % ruta_skin)
		return false

	var mesh_instance := get_node_or_null(nodo_skin_mesh_path) as MeshInstance3D
	if mesh_instance == null:
		push_warning("coche.gd: nodo_skin_mesh_path no apunta a MeshInstance3D")
		return false

	if superficie_skin < 0:
		push_warning("coche.gd: superficie_skin invalida (%d)" % superficie_skin)
		return false

	var material := _obtener_material_skin(mesh_instance, superficie_skin)
	if material == null:
		push_warning("coche.gd: no se encontro material para aplicar skin")
		return false

	var material_skin := material.duplicate() as Material
	if material_skin == null:
		push_warning("coche.gd: no se pudo duplicar material para skin")
		return false

	if material_skin is StandardMaterial3D:
		(material_skin as StandardMaterial3D).albedo_texture = textura
	elif material_skin is ShaderMaterial:
		(material_skin as ShaderMaterial).set_shader_parameter(parametro_shader_skin, textura)
	else:
		push_warning("coche.gd: tipo de material no soportado para skin")
		return false

	mesh_instance.set_surface_override_material(superficie_skin, material_skin)
	skin_actual = nombre_archivo
	return true

func quitar_skin() -> void:
	var mesh_instance := get_node_or_null(nodo_skin_mesh_path) as MeshInstance3D
	if mesh_instance == null:
		return

	if superficie_skin >= 0:
		mesh_instance.set_surface_override_material(superficie_skin, null)
	skin_actual = ""

func _obtener_material_skin(mesh_instance: MeshInstance3D, indice_superficie: int) -> Material:
	var material := mesh_instance.get_surface_override_material(indice_superficie)
	if material != null:
		return material

	if mesh_instance.mesh != null and indice_superficie < mesh_instance.mesh.get_surface_count():
		return mesh_instance.mesh.surface_get_material(indice_superficie)

	return null

# ════════════════════════════════════════════════════════════════════
#  CÁMARAS
# ════════════════════════════════════════════════════════════════════

func _al_cambiar_camara(id: int) -> void:
	indice_camara = id

	match id:
		0:
			# Cámara externa fija en Cams_pivot
			if cam_externa:
				cam_externa.make_current()
				spring_arm.set_process(false)
			else:
				push_warning("coche.gd: cam_externa no existe, usando cámara alternativa")
				if cam_interna:
					cam_interna.make_current()

		1:
			# Cámara interna del conductor
			if cam_interna:
				cam_interna.make_current()
				spring_arm.set_process(false)
			else:
				push_warning("coche.gd: cam_interna no existe")

		2:
			# Cámara del BrazoCamara con SpringArm (orbital)
			if cam_brazo and spring_arm:
				cam_brazo.make_current()
				spring_arm.set_process(true)
			else:
				push_warning("coche.gd: cam_brazo o spring_arm no existe")

func _on_camara_movida(relative: Vector2) -> void:
	if not activo: return

	var sensibilidad = 0.2

	match indice_camara:
		0:
			# Cámara externa: rota el pivot
			$Cams_pivot.rotation_degrees.y -= relative.x * sensibilidad
			$Cams_pivot.rotation_degrees.x -= relative.y * sensibilidad
			$Cams_pivot.rotation_degrees.x  = clamp($Cams_pivot.rotation_degrees.x, -50.0, 25.0)
		1:
			# Cámara interna: rota la cámara directamente
			cam_interna.rotation_degrees.y -= relative.x * (sensibilidad * 0.7)
			cam_interna.rotation_degrees.x -= relative.y * (sensibilidad * 0.7)
			cam_interna.rotation_degrees.x  = clamp(cam_interna.rotation_degrees.x, -45.0, 45.0)
			cam_interna.rotation_degrees.y  = clamp(cam_interna.rotation_degrees.y, -110.0, 110.0)
		2:
			# BrazoCamara: rota el SpringArm
			spring_arm.rotation_degrees.y -= relative.x * sensibilidad
			spring_arm.rotation_degrees.x -= relative.y * sensibilidad
			spring_arm.rotation_degrees.x  = clamp(spring_arm.rotation_degrees.x, -50.0, 25.0)

# ════════════════════════════════════════════════════════════════════
#  SUBIR / BAJAR
# ════════════════════════════════════════════════════════════════════

func subir_jugador(p_jugador: Node3D) -> void:
	if activo: return
	activo = true
	freeze = false
	jugador_ref = p_jugador

	var ui_pie = p_jugador.find_child("UIpie", true, false)
	if ui_pie:
		ui_pie.visible = false

	if ui_vehiculo:
		ui_vehiculo.visible = true

	# Usar el nuevo sistema de InputVehiculo
	InputVehiculo.start_driving()
	# NO encender motor ni cambiar marcha automáticamente
	# El jugador debe arrancar manualmente después de subir

	p_jugador.hide()
	p_jugador.process_mode = Node.PROCESS_MODE_DISABLED

	_conectar_senales_ui()
	_alternar_sistemas(true)

	# Iniciar con cámara externa al subir
	GameManager.indice_camara = 0
	_al_cambiar_camara(0)

func bajar_jugador() -> void:
	if not activo: return
	activo = false

	if is_instance_valid(jugador_ref):
		var posicion_salida: Vector3 = global_position + (global_transform.basis.x * 3.5)
		var zona_entrada: Node3D = get_node_or_null("ZonaEntrada") as Node3D
		if zona_entrada:
			var dir_menos_x: Vector3 = -global_transform.basis.x.normalized()
			posicion_salida = zona_entrada.global_position + (dir_menos_x * salida_offset_lateral_desde_zona)
			posicion_salida.y += salida_offset_vertical

		var ui_pie = jugador_ref.find_child("UIpie", true, false)
		if ui_pie: ui_pie.visible = true

		jugador_ref.show()
		jugador_ref.process_mode = Node.PROCESS_MODE_INHERIT
		jugador_ref.global_position = posicion_salida

		var cam_p = jugador_ref.find_child("Camera3D", true, false)
		if cam_p: cam_p.make_current()

	if ui_vehiculo:
		ui_vehiculo.visible = false

	# Usar el nuevo sistema de InputVehiculo
	InputVehiculo.stop_driving()
	spring_arm.set_process(false)
	_alternar_sistemas(false)

# ════════════════════════════════════════════════════════════════════
#  SUCIEDAD
# ════════════════════════════════════════════════════════════════════

func notificar_impacto_vidrio(fuerza: float) -> void:
	for hijo in get_children():
		if hijo.has_method("check_collision_impact"):
			hijo.check_collision_impact(fuerza)

func notificar_suciedad(incremento: float) -> void:
	nivel_suciedad = clamp(nivel_suciedad + incremento, 0.0, 1.0)
	if chasis_visual:
		chasis_visual.set_instance_shader_parameter("dirt_amount", nivel_suciedad)

func notificar_barro(incremento: float) -> void:
	nivel_barro    = clamp(nivel_barro + incremento, 0.0, 1.0)
	nivel_suciedad = clamp(nivel_suciedad - incremento * 0.5, 0.0, 1.0)
	if chasis_visual:
		chasis_visual.set_instance_shader_parameter("mud_amount",  nivel_barro)
		chasis_visual.set_instance_shader_parameter("dirt_amount", nivel_suciedad)

func notificar_mojado(valor: float) -> void:
	nivel_mojado = clamp(valor, 0.0, 1.0)
	if chasis_visual:
		chasis_visual.set_instance_shader_parameter("wet_amount", nivel_mojado)

func limpiar_suciedad(cantidad: float) -> void:
	nivel_suciedad = clamp(nivel_suciedad - cantidad, 0.0, 1.0)
	nivel_barro    = clamp(nivel_barro    - cantidad, 0.0, 1.0)
	if chasis_visual:
		chasis_visual.set_instance_shader_parameter("dirt_amount", nivel_suciedad)
		chasis_visual.set_instance_shader_parameter("mud_amount",  nivel_barro)

# ════════════════════════════════════════════════════════════════════
#  DETECCIÓN
# ════════════════════════════════════════════════════════════════════

func _conectar_deteccion() -> void:
	for hijo in get_children():
		if hijo is Area3D:
			hijo.body_entered.connect(_on_body_entered)
			hijo.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jugador"):
		jugador_cerca = true
		jugador_ref   = body

func _on_body_exited(body: Node3D) -> void:
	if body == jugador_ref and not activo:
		jugador_cerca = false
		jugador_ref   = null

# ════════════════════════════════════════════════════════════════════
#  SISTEMAS INTERNOS
# ════════════════════════════════════════════════════════════════════

func _alternar_sistemas(estado: bool) -> void:
	if is_instance_valid(motor):
		motor.set_physics_process(estado)
	if is_instance_valid(llantas_controlador):
		llantas_controlador.set_physics_process(estado)

func _conectar_senales_ui() -> void:
	if not ui_vehiculo: return

	var zona_cam = ui_vehiculo.find_child("ZonaCamara", true, false)
	if zona_cam and zona_cam.has_signal("camara_movida"):
		if not zona_cam.camara_movida.is_connected(_on_camara_movida):
			zona_cam.camara_movida.connect(_on_camara_movida)

# ════════════════════════════════════════════════════════════════════
#  FÍSICA
# ════════════════════════════════════════════════════════════════════

func _physics_process(_delta: float) -> void:
	if not activo: return

	var v_vel = linear_velocity.length()
	
	# Arrastre aerodinámico
	if v_vel > velocidad_min_arrastre:
		var f_drag = -linear_velocity.normalized() * (v_vel * v_vel * arrastre_cuadratico)
		apply_central_force(f_drag)

	# Sistema de enderezado automático
	var up_actual   = global_transform.basis.y
	var inclinacion = up_actual.dot(Vector3.UP)
	if inclinacion < umbral_enderezado:
		var eje_correccion = up_actual.cross(Vector3.UP)
		apply_torque(eje_correccion * (1.0 - inclinacion) * torque_enderezado)

	# Estabilización trasera contra derrapes
	var inv_basis = global_transform.basis.inverse()
	var vel_local = inv_basis * linear_velocity
	var v_lateral = vel_local.x

	if abs(v_lateral) > umbral_deslizamiento_lateral and v_vel > velocidad_min_estabilizacion:
		var punto_trasero = global_transform.basis * Vector3(0, 0, brazo_estabilizacion_trasera)
		var fuerza_estab  = -global_transform.basis.x * v_lateral * masa_kg * estabilizacion_trasera
		apply_force(fuerza_estab, punto_trasero)

# ════════════════════════════════════════════════════════════════════
#  DEBUG
# ════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_U:
			notificar_suciedad(0.1)
		if event.keycode == KEY_B:
			notificar_barro(0.1)
		if event.keycode == KEY_M:
			notificar_mojado(min(nivel_mojado + 0.1, 1.0))
		if event.keycode == KEY_I:
			nivel_suciedad = 0.0
			nivel_barro    = 0.0
			nivel_mojado   = 0.0
			if chasis_visual:
				chasis_visual.set_instance_shader_parameter("dirt_amount", 0.0)
				chasis_visual.set_instance_shader_parameter("mud_amount",  0.0)
				chasis_visual.set_instance_shader_parameter("wet_amount",  0.0)
