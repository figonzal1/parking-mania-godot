class_name VehicleStats
extends Resource

# 1 meter = 40 pixels. Document in PROJECT_STRUCTURE.md before changing.
const PX_PER_M := 40.0

# Mass (game units; heavier = more inertia, needs more force to accelerate)
@export var mass: float = 10.0

# Center of mass Y offset in local body space (positive = toward rear)
@export var cog_y_offset: float = 0.0

# === ENGINE ===
@export var engine_force: float = 1500.0
@export var reverse_force_ratio: float = 0.4
@export var max_speed_forward: float = 600.0   # px/s (~54 km/h at 40px/m scale)
@export var max_speed_reverse: float = 150.0   # px/s (~13.5 km/h)

# === BRAKES ===
@export var brake_force: float = 2500.0

# === STEERING (Steering wheel simulation) ===
@export var max_wheel_angle_deg: float = 30.0
@export var max_steering_wheel_angle_deg: float = 1800.0
# Seconds to go from full lock to full lock
@export var lock_to_lock_time_s: float = 4.0
# Exponential return speed (k in exp(-k*delta)); higher = faster auto-center
@export var steering_return_factor: float = 3.0

# === LATERAL GRIP (per axle) ===
# Force applied per px/s of lateral velocity. Tune in sandbox:
#   too high -> snappy, no lateral movement
#   too low  -> fish-tailing, understeer
@export var cornering_stiffness_front: float = 300.0
@export var cornering_stiffness_rear: float = 350.0
# Maximum lateral force per axle (caps sliding at extreme angles)
@export var lateral_force_max: float = 5000.0

# === RESISTANCE & ENGINE BRAKING ===
# Constant opposing-motion force (tires + road friction), always active
@export var rolling_resistance: float = 80.0
# Force per px/s applied when off-throttle (engine compression braking)
# At max_speed_forward: total engine brake = engine_brake_coef * max_speed
@export var engine_brake_coef: float = 1.5

# === THROTTLE RESPONSE ===
# Seconds for throttle to reach ~63% of target input (diesel spool-up lag)
# 0 = instant response (arcade feel)
@export var throttle_response_time: float = 0.6
