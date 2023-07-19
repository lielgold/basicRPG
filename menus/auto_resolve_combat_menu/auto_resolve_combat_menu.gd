extends Control

onready var win_records_container = $ScrollContainer/VBoxContainer
const win_record_widget_resource = preload("res://menus/auto_resolve_combat_menu/win_record_widget.tscn")
const char_win_record_widget_resource = preload("res://menus/auto_resolve_combat_menu/char_win_record_widget.tscn")

var ownode_that_created_the_menu
var encounter_that_created_this_menu
var overworld

# initialize the menu. the call_scene is the combat scene this menu auto resolves
func initialize(overworld, ownode, event_of_this_node=null):
	self.ownode_that_created_the_menu = ownode
	self.overworld = overworld
	
	var win_records = Globals.win_records[ownode.current_fight_event.call_scene.resource_path]	
	for record in win_records_container.get_children():
		win_records_container.remove_child(record)
		record.queue_free()
	
	for record in win_records:
		# create new record widget
		var no_hp_lost = true
		var win_record_widget = win_record_widget_resource.instance()
		win_record_widget.initialize(self, record)
		
		for character_record in record:
			no_hp_lost = false
			
			# create a new character win record widget, and add it to the record widget
			var char_win_record_widget = char_win_record_widget_resource.instance()
			char_win_record_widget.initialize(character_record)
			win_record_widget.add_character_record(char_win_record_widget)
			
			# if there's not enough hp, disable the record widget
			var character_from_record = Globals.main_game.get_character_from_id(character_record.character_id)
			if character_from_record.hp - (character_record.hp_percentage_lost * character_from_record.max_hp) < 0:
				win_record_widget.disabled = true
				win_record_widget.show_disabled_notification()		
		
		# add record to win_records_container
		win_records_container.add_child(win_record_widget)		
		
		if no_hp_lost: win_record_widget.show_no_losses_message()


# initialize the menu. the call_scene is the combat scene this menu auto resolves
func initialize_v2(overworld, encounter_event):	
	self.overworld = overworld
	encounter_that_created_this_menu = encounter_event
	
	var win_records = Globals.win_records[encounter_event.call_scene.resource_path]	
	for record in win_records_container.get_children():
		win_records_container.remove_child(record)
		record.queue_free()
	
	for record in win_records:
		# create new record widget
		var no_hp_lost = true
		var win_record_widget = win_record_widget_resource.instance()
		win_record_widget.initialize(self, record)
		
		for character_record in record:
			no_hp_lost = false
			
			# create a new character win record widget, and add it to the record widget
			var char_win_record_widget = char_win_record_widget_resource.instance()
			char_win_record_widget.initialize(character_record)
			win_record_widget.add_character_record(char_win_record_widget)
			
			# if there's not enough hp, disable the record widget
			var character_from_record = Globals.main_game.get_character_from_id(character_record.character_id)
			if character_from_record.hp - (character_record.hp_percentage_lost * character_from_record.max_hp) < 0:
				win_record_widget.disabled = true
				win_record_widget.show_disabled_notification()		
		
		# add record to win_records_container
		win_records_container.add_child(win_record_widget)		
		
		if no_hp_lost: win_record_widget.show_no_losses_message()

func player_refused_auto_resolve_and_chose_to_fight():
	hide()
#	ownode_that_created_the_menu.auto_resolve_refused()
	encounter_that_created_this_menu.auto_resolve_refused()

	

# Called when the node enters the scene tree for the first time.
func _ready():
	$fight_anyway_button.connect("pressed",self,"player_refused_auto_resolve_and_chose_to_fight")
	

# chosen a record of a previous victory in the fight, pay the price specified in the record and mark the fight as won
func chosen_win_record(win_record_data):
	# reduce the hp as specified in the record
	for r in win_record_data:
		var character = Globals.main_game.get_character_from_id(r.character_id)
		character.hp -= r.hp_percentage_lost * character.max_hp
	
	#mark the fight as won before returning to the overworld
	encounter_that_created_this_menu.node_of_this_event.who_won_combat = Globals.WHO_WON.PLAYER
	overworld.return_from_combat_encounter(encounter_that_created_this_menu.node_of_this_event)
	hide()

func _input(event):
	#close the menu if clicked outside of it
	if (event is InputEventMouseButton) and event.pressed:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0),rect_size).has_point(evLocal.position):
			hide()
