extends Control


func initialize(win_record):
	var character = Globals.main_game.get_character_from_id(win_record.character_id)
	$portrait.texture = character.portrait
	$hp_percentage_lost.text = String(int(win_record.hp_percentage_lost*100)) + "% hp lost" #the number shown in the gui is rounded, it's not the real number
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
