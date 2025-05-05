class_name PlayerInput extends Node

@onready var _player: Player = get_parent()

var input_dir : float
var is_weapon_firing: bool = false

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

func _gather():
	# In this case, input should be client authority
	if not is_multiplayer_authority() || _player.paused:
		return
	
	input_dir = Input.get_axis("up", "down")
	is_weapon_firing = Input.is_action_pressed("fire")
		
func _exit_tree():
	NetworkTime.before_tick_loop.disconnect(_gather)
