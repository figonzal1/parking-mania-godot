# 📁 Estructura del Proyecto - Parking Mania

## 🎯 Organización de Carpetas

### `/scenes/` - Escenas del juego
Contiene todas las escenas (.tscn) organizadas por categoría.

- **`/levels/`** - Niveles del juego
  - `level_1.tscn`, `level_2.tscn`, etc.
  - Cada nivel es una escena completa jugable

- **`/vehicles/`** - Vehículos reutilizables
  - `truck.tscn` - Camión principal
  - `car.tscn` - Otros vehículos (futuro)
  
- **`/environment/`** - Elementos del entorno
  - `parking_zone.tscn` - Zona de estacionamiento
  - `obstacle.tscn` - Obstáculos
  
- **`/ui/`** - Interfaces de usuario
  - `main_menu.tscn` - Menú principal
  - `hud.tscn` - HUD en juego
  - `pause_menu.tscn` - Menú de pausa

---

### `/scripts/` - Scripts GDScript
Contiene todos los scripts (.gd) separados de las escenas.

- **`/levels/`** - Scripts de niveles
  - `level_base.gd` - Clase base para niveles
  
- **`/vehicles/`** - Scripts de vehículos
  - `truck.gd` - Lógica del camión
  
- **`/environment/`** - Scripts del entorno
  - `parking_zone.gd` - Lógica de zona de parking
  
- **`/managers/`** - Sistemas globales (Singletons)
  - `game_manager.gd` - Gestión del juego
  - `level_manager.gd` - Gestión de niveles

---

### `/assets/` - Recursos del juego
Contiene todos los recursos multimedia.

- **`/sprites/`** - Imágenes y sprites
  - `/vehicles/` - truck.png, etc.
  - `/environment/` - parking_sprite.png, etc.
  - `/ui/` - botones, iconos, etc.
  
- **`/sounds/`** - Audio
  - `/sfx/` - Efectos de sonido
  - `/music/` - Música de fondo
  
- **`/fonts/`** - Fuentes tipográficas

---

### `/resources/` - Recursos de datos
Archivos de recursos (.tres) reutilizables.

- **`/vehicle_stats/`** - Estadísticas de vehículos
- **`/level_configs/`** - Configuraciones de niveles

---

## 📋 Convenciones de Nombres

### Archivos:
- **Escenas**: `snake_case.tscn` - Ejemplo: `level_1.tscn`
- **Scripts**: `snake_case.gd` - Ejemplo: `truck.gd`
- **Recursos**: `snake_case.tres` - Ejemplo: `truck_stats.tres`
- **Assets**: `snake_case.png` - Ejemplo: `truck_sprite.png`

### Carpetas:
- Todo en `snake_case` y plural cuando contenga múltiples items
- Ejemplo: `vehicles/`, `levels/`, `managers/`

---

## 🎮 Buenas Prácticas

### 1. **Separación de Responsabilidades**
- Escenas (.tscn) para estructura visual
- Scripts (.gd) para lógica
- Resources (.tres) para datos

### 2. **Reutilización**
- Crea escenas reutilizables (prefabs)
- Usa herencia de scripts cuando tenga sentido
- Centraliza configuraciones en recursos

### 3. **Escalabilidad**
- Organiza por funcionalidad, no por tipo
- Mantén jerarquías poco profundas (max 3-4 niveles)
- Usa nombres descriptivos

### 4. **Autoloads (Singletons)**
Registra managers globales en Project Settings:
- `GameManager` → scripts/managers/game_manager.gd
- `LevelManager` → scripts/managers/level_manager.gd

---

## 📝 Notas Adicionales

- Los archivos `.gdignore` en `/assets/` evitan que Godot importe carpetas innecesariamente
- Mantén `/scenes/` sincronizado con `/scripts/` (misma estructura)
- Crea carpetas nuevas solo cuando tengas 3+ archivos relacionados
