# 🎮 Sistema de Configuraciones - Documentación

## 📋 Estructura General

El sistema de configuraciones está dividido en dos partes:

### 1. **ConfiguracionManager.gd** (Autoload/Singleton)
- Ubicación: `Scripts/ConfiguracionManager.gd`
- Gestiona **todas las configuraciones** del juego
- Se inicializa automáticamente al iniciar el proyecto
- Accesible desde cualquier script: `ConfiguracionManager.obtener("audio", "volumen_general")`

### 2. **Escena ConfiguracionesUI** (scenes/configuraciones/)
- UI visual para que el usuario ajuste configuraciones
- Guarda automáticamente los cambios
- Se puede mostrar/ocultar como overlay en cualquier momento

---

## 🔧 Configuración en project.godot

Para usar el sistema, agrega el siguiente Autoload en `project.godot`:

### Opción 1: Editar manualmente project.godot
```ini
[autoload]

ConfiguracionManager="*res://Scripts/ConfiguracionManager.gd"
```

### Opción 2: Desde el editor
1. Ve a **Project → Project Settings → Autoload**
2. Carga el archivo `res://Scripts/ConfiguracionManager.gd`
3. Dale el nombre `ConfiguracionManager`
4. Presiona agregar

---

## 📚 Categorías de Configuración

### 🖼️ **Gráficos**
- `calidad` (0=Baja, 1=Media, 2=Alta)
- `sombras` (bool)
- `reflejos` (bool)
- `antialiasing` (bool)
- `resolucion` (string: "1920x1080")
- `pantalla_completa` (bool)
- `vsync` (bool)

### 🔊 **Audio**
- `volumen_general` (0-100)
- `volumen_musica` (0-100)
- `volumen_efectos` (0-100)
- `volumen_voces` (0-100)
- `mute_background` (bool)

### 🎮 **Juego**
- `subtitulos` (bool)
- `sensibilidad_camara` (0-100)
- `dificultad` (0=Fácil, 1=Normal, 2=Difícil)
- `velocidad_juego` (0.5-2.0)
- `mostrar_fps` (bool)
- `idioma` (string: "es_ES", "en_US")

### ⌨️ **Controles**
- `invertir_eje_x` (bool)
- `invertir_eje_y` (bool)
- `deadzone_joystick` (float: 0.0-1.0)

### ♿ **Accesibilidad**
- `daltonismo` (bool)
- `alto_contraste` (bool)
- `tamaño_texto` (float)

---

## 💻 Uso en Scripts

### Obtener una configuración
```gdscript
var volumen = ConfiguracionManager.obtener("audio", "volumen_general")
var dificultad = ConfiguracionManager.obtener("juego", "dificultad")
```

### Establecer una configuración
```gdscript
# Guarda automáticamente
ConfiguracionManager.establecer("audio", "volumen_musica", 75)

# Sin guardar (cambio temporal)
ConfiguracionManager.establecer("juego", "velocidad_juego", 1.5, false)
```

### Obtener toda una sección
```gdscript
var config_audio = ConfiguracionManager.obtener_seccion("audio")
# Devuelve: { "volumen_general": 80, "volumen_musica": 70, ... }
```

### Restaurar valores por defecto
```gdscript
ConfiguracionManager.restaurar_defectos()  # Todas las configuraciones
ConfiguracionManager.restaurar_seccion("audio")  # Una sección específica
```

### Conectarse a cambios
```gdscript
func _ready() -> void:
    ConfiguracionManager.configuracion_cambiada.connect(_on_config_changed)

func _on_config_changed(seccion: String, clave: String, valor: Variant) -> void:
    print("Cambio: %s/%s = %s" % [seccion, clave, valor])
```

---

## 🎨 Mostrar/Ocultar la UI

### Desde MainMenu
```gdscript
# Para mostrar configuraciones
var configuraciones_ui = load("res://scenes/configuraciones/configuraciones.tscn").instantiate()
add_child(configuraciones_ui)
configuraciones_ui.mostrar_configuraciones()

# Para ocultarlas
configuraciones_ui.ocultar_configuraciones()
```

---

## 📁 Estructura de Carpetas

```
scenes/
├── configuraciones/
│   ├── configuraciones.tscn        # Escena UI
│   ├── configuraciones.gd          # Script de la UI
│   └── fondo.png                   # Imagen de fondo
│
Scripts/
├── ConfiguracionManager.gd         # Gestor central (Autoload)
```

---

## ⚙️ Almacenamiento

### Ubicación de archivos guardados:
- **Configuraciones**: `user://configuraciones.cfg`
- **Datos de juego**: `user://datos_juego.save`

### Rutas en diferentes plataformas:
- **Windows**: `C:\Users\[usuario]\AppData\Roaming\Godot\app_userdata\[nombre_app]/`
- **Linux**: `~/.local/share/godot/app_userdata/[nombre_app]/`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/[nombre_app]/`

---

## 🎯 Ejemplos Prácticos

### Ajustar volumen desde script
```gdscript
extends Node3D

func _process(delta):
    if Input.is_action_pressed("aumentar_volumen"):
        var vol_actual = ConfiguracionManager.obtener("audio", "volumen_general")
        ConfiguracionManager.establecer("audio", "volumen_general", vol_actual + 5)
```

### Cambiar dificultad en pausa
```gdscript
func cambiar_dificultad(nueva_dificultad: int) -> void:
    ConfiguracionManager.establecer("juego", "dificultad", nueva_dificultad)
    _aplicar_dificultad(nueva_dificultad)
```

### Adaptar HUD según configuración
```gdscript
func _ready() -> void:
    if ConfiguracionManager.obtener("juego", "subtitulos"):
        pantalla_subtitulos.show()
    else:
        pantalla_subtitulos.hide()
```

---

## 🔔 Señales Disponibles

```gdscript
# Cuando cualquier configuración cambia
ConfiguracionManager.configuracion_cambiada.connect(_on_config_changed)

# Cuando se guardan configuraciones
ConfiguracionManager.configuraciones_guardadas.connect(_on_guardadas)

# Cuando se restauran valores por defecto
ConfiguracionManager.configuraciones_restauradas.connect(_on_restauradas)
```

---

## 🐛 Debugging

Habilita mensajes de debug en la consola:
```gdscript
# En ConfiguracionManager.gd ya está configurado para mostrar:
# ✓ Carga exitosa
# ✗ Errores
# ℹ Información
# 🔊 Estado de audio
# 📊 Estado de gráficos
```

---

## 📝 Próximas Mejoras

- [ ] Perfiles de configuración guardables
- [ ] Reasignación de controles en UI
- [ ] Exportar/Importar configuraciones
- [ ] Sincronización en la nube
- [ ] Presets de configuración (Gaming, Rendimiento, Calidad)

---

## ❓ FAQ

**P: ¿Puedo cambiar configuraciones sin guardarlas?**
R: Sí, usa `establecer(..., false)` como último parámetro.

**P: ¿Cómo agrego una nueva configuración?**
R: Edita el diccionario en `_inicializar_configuraciones()` en ConfiguracionManager.gd

**P: ¿Dónde se guardan los archivos?**
R: En la carpeta `user://` específica de tu SO.

**P: ¿Se pueden importar configuraciones desde otro juego?**
R: Sí, usa `ConfiguracionManager.importar_configuraciones(json_string)`
