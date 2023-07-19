extends Control

var bar_red = preload("res://character/health_bar/assets/barHorizontal_red.png")
#var bar_green = preload("res://character/health_bar/assets/barHorizontal_green.png")
var bar_green = preload("res://assets/hp bar.png")
var bar_yellow = preload("res://character/health_bar/assets/barHorizontal_yellow.png")

onready var healthbar = $hp_progress_bar
onready var temp_healthbar = $temp_hp_progress_bar
onready var hp_number = $hp_number


func _ready():
	return
#	healthbar.max_value = get_parent().get_max_hp()
#	temp_healthbar.max_value = get_parent().get_max_hp()
#	hp_number.text = String(get_parent().get_max_hp())

func initialize(character :Character):
	healthbar = $hp_progress_bar
	temp_healthbar = $temp_hp_progress_bar
	hp_number = $hp_number
	healthbar.max_value = character.get_max_hp()
	temp_healthbar.max_value = character.get_max_hp()
	hp_number.text = String(character.get_max_hp())

func update_healthbar(new_hp_value,new_temp_hp_value):	
#	healthbar.texture_progress = bar_green
#	if new_hp_value < healthbar.max_value * 0.7:
#		healthbar.texture_progress = bar_yellow
#	if new_hp_value < healthbar.max_value * 0.35:
#		healthbar.texture_progress = bar_red
		
	if new_hp_value < healthbar.max_value:
		show()

	healthbar.value = new_hp_value	
	temp_healthbar.value = new_hp_value+new_temp_hp_value
	hp_number.text = String(new_hp_value+new_temp_hp_value)
