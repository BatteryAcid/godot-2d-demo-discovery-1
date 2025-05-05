extends Control

@export var player1_score_label: RichTextLabel
@export var player2_score_label: RichTextLabel
@export var winner_label: RichTextLabel
@export var play_again_btn: Button
@export var waiting_for_players_label: RichTextLabel

var player1_score: int
var player2_score: int
var winner: int # TODO: refactor to use player name some day

func _ready():
	player1_score_label.text = "Player 1 Score\n%s" % player1_score
	player2_score_label.text = "Player 2 Score\n%s" % player2_score
	winner_label.text = "Winner\r Player %s!" % winner
	
func _on_main_menu_pressed():
	NetworkManager.disconnect_from_game()
	queue_free()

func _on_play_again_pressed():
	play_again_btn.hide()
	waiting_for_players_label.show()
	NetworkManager.ready_play_again()
