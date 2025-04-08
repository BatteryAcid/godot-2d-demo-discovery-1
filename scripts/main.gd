extends Control

@export var host_ip: LineEdit
@export var game_id: LineEdit

func _on_host_game_pressed():
	if host_ip.text:
		NetworkManager.host_game(host_ip.text)

func _on_join_game_pressed():
	if host_ip.text && game_id.text:
		NetworkManager.join_game(host_ip.text, game_id.text)

func _on_exit_pressed():
	get_tree().quit()
