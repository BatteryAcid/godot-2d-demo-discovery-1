class_name BlasterWeapon extends NetworkWeapon2D

@export var projectile: PackedScene
@export var fire_cooldown: float = 0.15

@onready var input: PlayerInput = $"../PlayerInput"

var last_fire: int = -1

func _ready():
	NetworkTime.on_tick.connect(_tick)

func _can_fire() -> bool:
	return NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _after_fire(projectile: Node2D):
	last_fire = get_fired_tick()

func _spawn() -> Node2D:
	var blaster_projectile: BlasterProjectile = projectile.instantiate() as BlasterProjectile
	get_tree().root.add_child(blaster_projectile, true)
	blaster_projectile.global_transform = get_parent().global_transform
	
	if not get_parent().name == "1": # if not host
		blaster_projectile.fire_dir = -1
		
	return blaster_projectile

func _tick(_delta: float, _t: int):
	if input.is_weapon_firing:
		print("Fire weapon")
		fire()
