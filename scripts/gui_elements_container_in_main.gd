extends Control

onready var party_menu = $party_menu_container
onready var character_menu = $character_menu
onready var auto_resolve_combat_menu = $auto_resolve_combat_menu
onready var save_load_menu = $save_load_menu
onready var animation_player = $AnimationPlayer
onready var player_got_rewards_menu = $player_got_rewards_menu
onready var encounter_menu = $encounter_menu


# Called when the node enters the scene tree for the first time.
func _ready():
	hide_all_gui_elements()	

# Reset gui. Used after loading the game as part of reseting main node
func reset_gui():
	party_menu.start_party_menu()
	
	

func hide_all_gui_elements():
	for gui_element in get_children():
		if not gui_element is AnimationPlayer:
			gui_element.hide()

func play_general_message(message:String):
	animation_player.get_node("general_message").text = message
	animation_player.play("show_general_message")
