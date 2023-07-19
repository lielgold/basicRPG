extends Control

var encounter_event
var encounter_text:String
var encounter_image:Texture

func initialize(encounter_event_of_this_menu, encounter_menu_text:String, encounter_menu_picture:Texture):
	self.encounter_event = encounter_event_of_this_menu
	$encounter_text.text = encounter_menu_text
	$encounter_image.texture = encounter_menu_picture

func _go_back_button_pressed():
	hide()

func _fight_button_pressed():	
	encounter_event.encounter_menu_pressed_fight()
	hide()

# Called when the node enters the scene tree for the first time.
func _ready():
	$go_back_button.connect("pressed",self,"_go_back_button_pressed")
	$fight_button.connect("pressed",self,"_fight_button_pressed")
	

