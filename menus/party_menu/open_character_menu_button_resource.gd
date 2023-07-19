extends Control

const character_menu_resource = preload("res://menus/chararter_menu/character menu.tscn")
const draft_button_join_texture = preload("res://assets/menus/draft button join.png")
const draft_button_join_hover_texture = preload("res://assets/menus/draft button join on hover.png")
const draft_button_leave_texture = preload("res://assets/menus/draft button leave.png")
const draft_button_leave_hover_texture = preload("res://assets/menus/draft button leave on hover.png")
const draft_button_dead_texture = preload("res://assets/menus/draft button dead.png")


var character:Character

onready var draft_me_button = $draft_me_button2
onready var open_character_menu_button = $open_character_menu_button

# BUG_DONT_REMOVE_ME - need to keep this button here due to a save / load bug. Can be removed after a rewrite.
# it doesn't do anything, so no harm done... but yeah, ugly.

var character_drafted = false

# Called when the node enters the scene tree for the first time.
func _ready():
	draft_me_button.hide()
	


func initialize(character:Character):
	self.character = character
	draft_me_button = $draft_me_button2
	open_character_menu_button = $open_character_menu_button
		
	open_character_menu_button.texture_normal = character.portrait

func _on_open_character_menu_button_pressed():
	for c in Globals.main_game.gui.get_children():
		if c is CharacterMenu_V3:
			c.get_parent().remove_child(c)
			
	var menu = character_menu_resource.instance()
	menu.initialize_menu(character)
			
	Globals.main_game.gui.add_child(menu)	
	menu.show()

func show_draft_button():
	draft_me_button.show()
	if !character.is_alive():
		#draft_me_button.text = "Dead"
		draft_me_button.disabled = true
		draft_me_button.texture_normal = draft_button_dead_texture
	
func hide_draft_button():
	draft_me_button.hide()	


func _on_draft_me_button_pressed():
	if !character_drafted:
		# remove character
		var character_added = Globals.combat_control.add_player_character(character)
		if character_added:
			character_drafted = true
			draft_me_button.texture_normal = draft_button_leave_texture
			draft_me_button.texture_hover = draft_button_leave_hover_texture
	else:
		# character joins
		character_drafted = false
		draft_me_button.texture_normal = draft_button_join_texture
		draft_me_button.texture_hover = draft_button_join_hover_texture		
		Globals.combat_control.remove_player_character(character, true)
