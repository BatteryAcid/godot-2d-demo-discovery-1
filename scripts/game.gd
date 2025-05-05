extends Node2D

# TODO:
# - add health pickups, could tack this on for a later video demonstrating RPCs
# - Powerups (speed/bullets)

signal player_killed

@export var connection_lifecycle_handler: PackedScene
@export var player_spawn_manager: PackedScene
@export var player_spawn: Node2D

const MATCH_OVER_KILL_THRESHOLD: int = 1

var players_in_game: Dictionary = {}

func _ready():
	# We don't have authority established yet, so use the is_hosting check instead
	if NetworkManager.is_hosting_game:
		print("Game: On hosting peer!")

		# Add these only to the host
		
		var psm = player_spawn_manager.instantiate()
		var clh = connection_lifecycle_handler.instantiate()
		
		psm.player_spawn = player_spawn
		psm.connection_lifecycle_handler = clh # Pass in dependency
		psm.game_play_node = self
		
		add_child(psm)
		add_child(clh)
		
		player_killed.connect(_player_killed)

func _player_killed(player_id: int):
	if not is_multiplayer_authority():
		return 

	#print("Player %s killed!" % player_id)
	if players_in_game.has(player_id):
		var dead_player = players_in_game.get(player_id)
		dead_player.death_count += 1
		
		print("Player %s has been killed %s times" % [player_id, dead_player.death_count])
		
		if dead_player.death_count >= MATCH_OVER_KILL_THRESHOLD: # Losing player has been killed 5 times
			for player_id_key in players_in_game.keys():
				if player_id != player_id_key: # winning player
					print("Player %s wins!" % player_id_key)
					
					# We do this instead of having a "game over" scene
					set_pause_game()
					mark_players_unready()
					
					# Assuming the 0th element is always player 1, since they are host
					# Also, flip the index as score correlates to how many times the other player died
					show_scores_view.rpc(players_in_game[players_in_game.keys()[1]].death_count, players_in_game[players_in_game.keys()[0]].death_count, player_id_key)
					break

# Doesn't really pause game, just stops collecting input
func set_pause_game(should_pause: bool = true):
	if not is_multiplayer_authority():
		return

	for player in player_spawn.get_children():
		if player is Player:
			player.paused = should_pause

func mark_players_unready():
	if not is_multiplayer_authority():
		return

	for player in player_spawn.get_children():
		if player is Player:
			player.ready_play_again = false

# Runs on clients
@rpc("authority", "call_local", "reliable")
func show_scores_view(p1_scores: int, p2_scores: int, winner: int):
	print("Show scores view")
	NetworkManager.show_scores(p1_scores, p2_scores, winner)

# Runs on clients
@rpc("authority", "call_local", "reliable")
func hide_scores_view():
	print("Hidescores view")
	NetworkManager.hide_scores()

# Runs on authority, must use 'call_local' to make sure it also runs on Host
@rpc("any_peer", "call_local", "reliable")
func ready_play_again():
	print("Ready play again rpc")
	if not is_multiplayer_authority():
		return
	
	var player_ready_count = 0
	for player in player_spawn.get_children():
		if player is Player:
			if player.name == str(multiplayer.get_remote_sender_id()):
				player.ready_play_again = true
				player_ready_count += 1
				player.reset_health()
				print("Set player ready %s" % player.name)
			elif player.ready_play_again:
				# This wasn't the requesting ready-player, but they were already ready!
				player_ready_count += 1
				print("Player already ready %s" % player.name)
				
	if player_ready_count == 2:
		# All players ready to play again, unpause and RPC to hide scores view
		set_pause_game(false)
		hide_scores_view.rpc()
