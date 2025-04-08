class_name Player extends CharacterBody2D

@export var _player_input: PlayerInput
@onready var rollback_synchronizer = $RollbackSynchronizer

const SPEED = 200.0

# TODO: setup player input using RollbackSynchronizer/TickInterpolator
func _enter_tree():
	_player_input.set_multiplayer_authority(str(name).to_int())
	
func _ready():
	# Call this after setting authority
	# https://foxssake.github.io/netfox/latest/netfox/tutorials/responsive-player-movement/#ownership
	rollback_synchronizer.process_settings()

func _rollback_tick(delta, tick, is_fresh):
	var direction = _player_input.input_dir
	if direction:
		velocity.y = direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
