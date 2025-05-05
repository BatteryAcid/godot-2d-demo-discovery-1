class_name BlasterWeapon extends NetworkWeapon2D

@export var fire_out: AnimatedSprite2D
@export var fire_cooldown: float = 0.6
@export var projectile: PackedScene
@export var input: PlayerInput

var last_fire: int = -1

var _parent_player

func _ready():
	NetworkTime.on_tick.connect(_tick)
	distance_threshold = 10 # The default 1 was too small for this map size and speed
	fire_out.hide()
	
	_parent_player = get_parent()

# Phantom projectiles: 
# The reason this shows up is because it is actually spawned locally by the call to fire()
# which spawns it, then sends RPCs to verify, but may get rejected. So you may see "phantom" 
# projectiles for a second.
func _can_fire() -> bool:
	return not _parent_player._player_dead && NetworkTime.seconds_between(last_fire, NetworkTime.tick) >= fire_cooldown

func _after_fire(projectile: Node2D):
	last_fire = get_fired_tick()
	
	# Let the animation play for a little before stopping
	await get_tree().create_timer(0.25).timeout
	fire_out.hide()

# Spawn is called once locally upon firing then reconcilled with the server's position of the spawn
func _spawn() -> Node2D:
	fire_out.show()
	fire_out.play()
	
	var blaster_projectile: BlasterProjectile = projectile.instantiate() as BlasterProjectile

	# Puts the projectile right under the wing
	blaster_projectile.global_transform = _parent_player.global_transform.translated(Vector2(0, 18))
	blaster_projectile.fired_by = _parent_player
	
	if not _parent_player.name == "1": # if not host
		blaster_projectile.fire_dir = -1
		fire_out.offset.x = 5

	# We add these here and not at the root of the tree so that when we move away from the Game scene
	# it will clean everything up
	get_tree().current_scene.find_child("Projectiles").add_child(blaster_projectile, true)
		
	return blaster_projectile

func _tick(_delta: float, _t: int):
	if input.is_weapon_firing:
		fire()
