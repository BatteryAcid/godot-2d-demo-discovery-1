class_name BlasterProjectile extends Node2D

@export var speed: float = 500.0
@export var distance: float = 1200.0

var _distance_left: float
var fire_dir: int = 1

func _ready():
	NetworkTime.on_tick.connect(_tick)
	_distance_left = distance
	
func _tick(delta, _t):
	var dist = speed * delta
	_distance_left -= dist

	if _distance_left < 0:
		queue_free()

	translate(Vector2(fire_dir * dist, 0))
