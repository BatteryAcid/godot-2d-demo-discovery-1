extends Control

func _on_copy_gameid_pressed():
	DisplayServer.clipboard_set(NetworkManager.active_game_id)

func _on_copy_host_pressed():
	DisplayServer.clipboard_set(NetworkManager.active_host_ip)

func _on_main_menu_pressed():
	NetworkManager.disconnect_from_game()
