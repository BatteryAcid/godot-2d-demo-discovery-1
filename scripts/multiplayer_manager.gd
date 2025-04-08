extends Node

@export var _player_spawn: Node2D
@export var _player_scene: PackedScene

var _players_in_game: Dictionary = {}

func _ready():
	print("MultiplayerManager ready!")

	# This section is for the authority (host/server), so we don't check for authority
	# unless a peer has been established.
	if multiplayer.has_multiplayer_peer() && is_multiplayer_authority():
		# Leverage the peer connected signal to trigger the player spawn
		multiplayer.peer_connected.connect(_peer_connected)
		
		# Handle the disconnect signal here so we have access to what needs cleaned up in game.
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		
		# We don't want to add a player to a dedicated server instance
		if NetworkManager.is_hosting_game:
			print("Adding Host player to game...")
			_add_player_to_game(1)

func _add_player_to_game(network_id: int):
	if is_multiplayer_authority():
		print("Adding player to game: %s" % network_id)
		
		if _players_in_game.get(network_id) == null:
			var player_to_add = _player_scene.instantiate()
			player_to_add.name = str(network_id)
			_ready_player(player_to_add)
			
			_players_in_game[network_id] = player_to_add
			_player_spawn.add_child(player_to_add)
		else:
			print("Warning! Attempted to add existing player to game: %s" % network_id)

func _remove_player_from_game(network_id: int):
	if is_multiplayer_authority():
		print("Removing player from game: %s" % network_id)
		if _players_in_game.has(network_id):
			var player_to_remove = _players_in_game[network_id]
			if player_to_remove:
				player_to_remove.queue_free()		
				_players_in_game.erase(network_id)

# Setup initial or reload saved player properties
func _ready_player(player: Player):
	if is_multiplayer_authority():
		if player.name == "1":
			player.position = Vector2(50, 50)
		else:
			player.position = Vector2(1100, 500)

func _peer_connected(network_id: int):
	print("Peer connected: %s" % network_id)
	if is_multiplayer_authority():
		_add_player_to_game(network_id)
		
func _peer_disconnected(network_id: int):
	print("Peer disconnected: %s" % network_id)
	_remove_player_from_game(network_id)
