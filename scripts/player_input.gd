class_name PlayerInput extends Node

var input_dir : float
var is_weapon_firing: bool = false

func _ready():
	NetworkTime.before_tick_loop.connect(_gather)

func _gather():
	# In this case, should be client authority
	if is_multiplayer_authority():
		input_dir = Input.get_axis("ui_up", "ui_down")
		is_weapon_firing = Input.is_action_pressed("fire")
		
func _exit_tree():
	NetworkTime.before_tick_loop.disconnect(_gather)
