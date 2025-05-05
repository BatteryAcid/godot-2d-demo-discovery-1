class_name PlayerSpawnManager extends Node

# This script is currently only loaded/used on Host peer

@export var player_scene: PackedScene

var game_play_node
var connection_lifecycle_handler
var player_spawn: Node2D

func _enter_tree():
	# TODO: consider using NetworkEvents signals
	# https://github.com/foxssake/netfox/blob/c6647157bb08f97d1f4b2c7dcf79215c1b1f40ec/examples/forest-brawl/scripts/brawler-spawner.gd#L66
	connection_lifecycle_handler.on_peer_connected.connect(add_player_to_game)
	connection_lifecycle_handler.on_peer_disconnected.connect(remove_player_from_game)

func add_player_to_game(network_id: int):
	if is_multiplayer_authority():
		print("Adding player to game: %s" % network_id)

		if game_play_node.players_in_game.get(network_id) == null:
			var player_to_add = player_scene.instantiate()
			player_to_add.name = str(network_id)
			player_to_add._game_play_node = game_play_node
			_ready_player(player_to_add)

			game_play_node.players_in_game[network_id] = player_to_add
			player_spawn.add_child(player_to_add)
		else:
			print("Warning! Attempted to add existing player to game: %s" % network_id)

func remove_player_from_game(network_id: int):
	if is_multiplayer_authority():
		print("Removing player from game: %s" % network_id)
		if game_play_node.players_in_game.has(network_id):
			var player_to_remove = game_play_node.players_in_game[network_id]
			if player_to_remove:
				player_to_remove.queue_free()
				game_play_node.players_in_game.erase(network_id)

# Setup initial or reload saved player properties
func _ready_player(player: Player):
	if is_multiplayer_authority():
		player.global_transform = get_spawn_point(player.name)
		player._next_respawn_transform = player.global_transform
		player.visible = false
		
		# Player is always owned by the server
		player.set_multiplayer_authority(1)
		
		var input = player.find_child("PlayerInput")
		if input != null:
			input.set_multiplayer_authority(str(player.name).to_int())
		
		# Show loading on host once we have a new peer connected
		if player.name != "1":
			NetworkManager.show_loading()

func get_spawn_point(player_name) -> Transform2D:
	if player_name == "1": # For now, just check if you're the host, spawn on left side.
		return Transform2D(0, Vector2(100, randi_range(50, 570)))
	else:
		return Transform2D(0, Vector2(1000, randi_range(50, 570)))
