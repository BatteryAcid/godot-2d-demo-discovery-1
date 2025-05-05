class_name BlasterProjectile extends Area2D

@export var START_SPEED: float = 20.0
@export var MAX_SPEED: float = 600
@export var SPEED_ACC_INTERVAL: float = 50
@export var MAX_DISTANCE: float = 1200.0
@export var speed: float = START_SPEED
@export var _projectile_sprite: AnimatedSprite2D

var fire_dir: int = 1
var fired_by: Player

var _distance_left: float

func _ready():
	NetworkTime.on_tick.connect(_tick)
	_distance_left = MAX_DISTANCE
	
	# Set direction of projectile's animation
	if fire_dir < 0:
		_projectile_sprite.flip_h = false

func _tick(delta, _t):
	if speed < MAX_SPEED:
		speed += SPEED_ACC_INTERVAL
		
	var dist = speed * delta
	_distance_left -= dist

	if _distance_left < 0:
		queue_free()

	translate(Vector2(fire_dir * dist, 0))
	
func _on_body_entered(body):
	# print("Blaster hit: %s" % body.name)
	
	# Ignore hits to self
	if body == fired_by:
		return
	
	if body is Player:
		print("Player %s hit! " % body.name)
		if fired_by != null:
			body._register_hit(fired_by)
	
	# Clean up object whenever it hits something that's not the player firing it	
	_impact_on_hit()

func _impact_on_hit():
	print("Impact on hit")
	speed = 0 # stop on impact
	NetworkTime.on_tick.disconnect(_tick)
	
	_projectile_sprite.animation = "explode"
	await get_tree().create_timer(1).timeout 
	queue_free()
