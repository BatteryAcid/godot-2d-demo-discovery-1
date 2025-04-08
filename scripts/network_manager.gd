extends Node

const MAIN_MENU_SCENE = "res://scenes/main.tscn"
const GAME_SCENE = "res://scenes/game.tscn"
const _noray_network_scene = "res://scenes/noray_network.tscn"

var _active_network_node
var is_hosting_game = false
var active_host_ip = ""
var active_game_id = ""

func host_game(host: String):
	print("Hosting game: %s" % host)
	is_hosting_game = true
	active_host_ip = host
	
	var network_scene = load(_noray_network_scene)
	_active_network_node = network_scene.instantiate()
	add_child(_active_network_node)
	
	_active_network_node.create_server_peer(host)
	
	get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	
func join_game(host: String, game_id: String):
	print("Joining game at host: %s, with game id: %s" % [host, game_id])
	
	get_tree().call_deferred(&"change_scene_to_packed", preload(GAME_SCENE))
	
	var network_scene = load(_noray_network_scene)
	_active_network_node = network_scene.instantiate()
	add_child(_active_network_node)
	
	# Connect client-side lifecycle signals
	_active_network_node.network_server_disconnected.connect(disconnect_from_game)
	
	_active_network_node.create_client_peer(host, game_id)

# Use this to kill the network connection and clean up for return to main menu
func disconnect_from_game():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	
	NetworkTime.stop() # Stops the network type synchronizer from spamming ping RPCs after disconnect
	multiplayer.multiplayer_peer = null # Disconnect peer
	
	# Remove any child networks nodes
	for child in get_children():
		print("Removing child network node")
		child.queue_free()
	
	# Reset properties
	is_hosting_game = false
	active_host_ip = ""
	active_game_id = ""
	_active_network_node.queue_free()
	_active_network_node = null
	
	# Make sure player has mouse access to select menu options
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
