extends Node

const MAIN_MENU_SCENE = "res://scenes/main.tscn"
const GAME_SCENE = "res://scenes/game.tscn"
const LOADING_SCENE = "res://scenes/loading_screen.tscn"
const NORAY_NETWORK_SCENE = "res://scenes/noray_network.tscn"
const SCORES_SCENE = "res://scenes/scores_scene.tscn"

var is_hosting_game = false
var active_host_ip = ""
var active_game_id = ""

var _active_network_node
var _loading_screen: Control
var _scores_scene: Control

func host_game(host: String):
	print("Hosting game: %s" % host)
	
	show_loading()
	
	is_hosting_game = true
	active_host_ip = host

	var network_scene = load(NORAY_NETWORK_SCENE)
	_active_network_node = network_scene.instantiate()
	add_child(_active_network_node)
	
	# I think we need to await this process of registration and starting Noray host 
	# before we move to game scene. That would eliminate need for while-awaits in the game.gd.
	var err = await _active_network_node.create_server_peer(host)
	if err == OK:
		print("Finished create server peer")
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	
	hide_loading()
	
func join_game(host: String, game_id: String):
	print("Joining game at host: %s, with game id: %s" % [host, game_id])
	
	show_loading()
	
	var network_scene = load(NORAY_NETWORK_SCENE)
	_active_network_node = network_scene.instantiate()
	add_child(_active_network_node)
	
	# Connect client-side lifecycle signals
	_active_network_node.network_server_disconnected.connect(disconnect_from_game)
	
	var err = await _active_network_node.create_client_peer(host, game_id)
	if err == OK:
		print("Loading game scene")
		get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	else:
		# Something went wrong, show main menu again
		hide_loading()
	
# Use this to kill the network connection and clean up for return to main menu
func disconnect_from_game():
	Noray.disconnect_from_host()
	NetworkTime.stop() # Stops the network type synchronizer from spamming ping RPCs after disconnect
	
	var mp_peer = get_tree().get_multiplayer().multiplayer_peer
	if mp_peer != null:
		mp_peer.close()
		mp_peer = null
	
	# Remove any child networks nodes
	for child in get_children():
		print("Removing child network node")
		child.queue_free()

	get_tree().call_deferred(&"change_scene_to_packed", preload(MAIN_MENU_SCENE))
	
	# Reset properties
	is_hosting_game = false
	active_host_ip = ""
	active_game_id = ""
	_active_network_node.queue_free()
	_active_network_node = null
	
	# Make sure player has mouse access to select menu options
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func show_loading():
	_loading_screen = preload(LOADING_SCENE).instantiate()
	add_child(_loading_screen)
	
func hide_loading():
	_loading_screen.queue_free()

func show_scores(p1_scores: int, p2_scores: int, winner: int):
	_scores_scene = preload(SCORES_SCENE).instantiate()
	_scores_scene.player1_score = p1_scores
	_scores_scene.player2_score = p2_scores
	_scores_scene.winner = winner
	add_child(_scores_scene)

func ready_play_again():
	# Calls from client to authority
	get_tree().current_scene.ready_play_again.rpc_id(1)
	
func hide_scores():
	_scores_scene.queue_free()
