extends TextureRect

const status_effect_resource = preload("res://character/status_effects.gd")

var status_effect

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(status_effect):
	self.status_effect = status_effect	
	change_status_effect_duration(status_effect.duration)
	
	# set texture
	var new_texture = load(status_effect.icon_texture_resource_path)
	set_texture(new_texture)
	
	# set description
	hint_tooltip = status_effect.gui_name
	

func change_status_effect_duration(new_duration:int)->void:	
	$ColorRect/status_duration.text = String(new_duration)

