class_name ConnectionLifecycleHandler extends Node

# This script is currently only loaded/used on Host peer

# NOTE: I like this as a separate script so that you can swap it out for a different
# one if that network setup requires different lifecycle handling

signal on_peer_connected
signal on_peer_disconnected

func _ready():
	print("ConnectionLifecycleHandler ready!")

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
			on_peer_connected.emit(1)

func _peer_connected(network_id: int):
	print("Peer connected: %s" % network_id)
	if is_multiplayer_authority():
		on_peer_connected.emit(network_id)
		
func _peer_disconnected(network_id: int):
	print("Peer disconnected: %s" % network_id)
	on_peer_disconnected.emit(network_id)
