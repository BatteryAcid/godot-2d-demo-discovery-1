class_name Player extends CharacterBody2D

@export var _player_sprite: AnimatedSprite2D
@export var _player_input: PlayerInput
@export var _respawn_time: float = 2.0
@export var _health_bar: TextureProgressBar

@onready var rollback_synchronizer = $RollbackSynchronizer

const SPEED = 200.0
const STARTING_HEALTH: int = 5

var death_count = 0
var paused = false
var ready_play_again = false

var _game_play_node
var _player_spawn_manager: PlayerSpawnManager
var _respawn_tick: int = -1
var _respawn_count: int = 0
var _health = 5
var _health_colors = [Color.RED, Color.ORANGE_RED, Color.YELLOW, Color.GREEN_YELLOW, Color.LIME_GREEN]
var _player_dead = false
var _next_respawn_transform = Transform2D(0, Vector2(-10, -10))

func _enter_tree():
	_player_input.set_multiplayer_authority(str(name).to_int())
	
func _ready():
	# We can use authority checks in the Player's ready function as we already have a connection established
	if is_multiplayer_authority():
		# We don't want to use/load this on non-authority peers
		_player_spawn_manager = get_tree().current_scene.get_node("PlayerSpawnManager")
		
		if str(name).to_int() == 1:
			visible = true # mark host player visible 
		else:
			# For non-host player, delay visiblity flag until time is synched
			# We run on authority (host) so the visible flag can be synched to client
			while not NetworkTime.is_client_synced(str(name).to_int()):
				await NetworkTime.after_client_sync
			
			visible = true # Make player visible 
			_ready_player_for_game.rpc_id(str(name).to_int())
			# Keeps loading screen active on Host for an extra second while other player loads.
			# Even though this block was authority-side setup for other player, hiding the loading
			# screen here applies to the Host peer.
			await get_tree().create_timer(1).timeout 
			NetworkManager.hide_loading()
	
	if str(name).to_int() != 1:
		_player_sprite.animation = "ship2"
	
	# Call this after setting authority
	# https://foxssake.github.io/netfox/latest/netfox/tutorials/responsive-player-movement/#ownership
	rollback_synchronizer.process_settings()

# Use this for any final setup needed to be done on the client before starting match
@rpc("authority", "reliable", "call_remote")
func _ready_player_for_game():
	# Wait another second to allow the jitters to smooth out
	await get_tree().create_timer(1).timeout
	NetworkManager.hide_loading()
	print("Player in game!")

func _physics_process(delta):
	_health_bar.value = _health

	if _health > 0:
		var tp = _health_bar.texture_progress
		tp.gradient.colors[0] = _health_colors[_health - 1]

# NOTE: Rollback_tick should execute the same code on all peers. Using awaits are dangerous as by the time it returns, we may be on a different tick.
func _rollback_tick(delta, tick, is_fresh):
	# Respawn once we've met the respawn tick cooldown
	if tick == _respawn_tick:
		# print("Respawn on peer: %s" % multiplayer.get_unique_id())
		velocity = Vector2.ZERO
		reset_health()
		_player_dead = false
		visible = true
	elif tick < _respawn_tick and _player_dead:
		# Update player position before they respawn
		# That way, once we pass our respawn cooldown (the above conditional), we are ready to set visible
		global_transform = _next_respawn_transform

	var direction = _player_input.input_dir
	if direction:
		velocity.y = direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	velocity *= NetworkTime.physics_factor
	move_and_slide()
	velocity /= NetworkTime.physics_factor
	
	# If our player is freshly dead
	if _player_dead and tick > _respawn_tick and is_fresh:
		var respawn_cooldown = _respawn_time * NetworkTime.tickrate
		_respawn_tick = tick + respawn_cooldown
		_respawn_count += 1

func _register_hit(from: Player):
	# Ignore calls to hit from self
	if from == self:
		return
	
	if is_multiplayer_authority():
		if _health > 0:
			_health -= 1
			print("health %s" % _health)
		
		if _health <= 0 and not _player_dead:
			print("Marking player dead...")
			_game_play_node.player_killed.emit(name.to_int())
			_player_dead = true
			visible = false
			velocity = Vector2.ZERO
			_next_respawn_transform = _player_spawn_manager.get_spawn_point(name)

func reset_health():
	if not is_multiplayer_authority():
		return
	_health = STARTING_HEALTH
