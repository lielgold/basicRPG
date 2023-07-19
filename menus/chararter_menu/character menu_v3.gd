extends Control

class_name CharacterMenu_V3

const ability_increase_widget_resource = preload("res://menus/chararter_menu/ability_increase_widget.tscn")
const stat_increase_widget_resource = preload("res://menus/chararter_menu/stat_levelup_widget.tscn")


signal xp_changed()
signal stats_changed()
signal ability_decreased()
signal ability_increased()
signal item_active_pressed(button)
signal changed_inventory_items()

var character:Character
var portrait
var stats
var increase_stats
var abilities_panel
var inventory_menu
var inventory_button_1:Button
var inventory_button_2:Button
var item_active_1:Button
var item_active_2:Button

onready var character_name = $character_name
onready var xp_points = $xp_points



var selected_item_active = null #this is an array of [selected item slot, selected item]

# Called when the node enters the scene tree for the first time.
func _ready():
	xp_points = $xp_points
	hide()
	
func initialize_menu(character):
	self.character = character
	
	connect("xp_changed", self, "_on_xp_changed")
	connect("stats_changed", self, "_update_stats_gui")	
	connect("ability_decreased", self, "_on_ability_level_down")
	connect("ability_increased", self, "_on_ability_level_up")
	connect("changed_inventory_items", self, "_on_inventory_menu_changed_inventory_items")
	

	portrait = get_node("portrait")
	stats = $stats
	increase_stats = $increase_stats
	abilities_panel = $abilities
	inventory_menu = $inventory_menu
	inventory_button_1 = $items_container/inventory_item_button1
	inventory_button_2 = $items_container/inventory_item_button2
	item_active_1 = $items_container/item_active_1
	item_active_2 = $items_container/item_active_2
	character_name = $character_name
	xp_points = $xp_points
	
	show()
	
	# general
	_on_xp_changed()
	portrait.set_texture(character.portrait)
	character_name.text = character.character_name
	
	#stats information  panel
	_update_stats_gui()
	
	# stats level up panel
	for c in increase_stats.get_children():
		increase_stats.remove_child(c)
		c.queue_free()
		
	for stat in character.stat_levelups_v2:
		var stat_widget = stat_increase_widget_resource.instance()
		stat_widget.initialize(self,stat)
		increase_stats.add_child(stat_widget)

	#abilities panel
	for b in abilities_panel.get_children():
		abilities_panel.remove_child(b)
		b.queue_free()
	
	for ability in character.abilities_manager.get_children():
		var a_widget = ability_increase_widget_resource.instance()
		a_widget.initialize(self, ability)
		abilities_panel.add_child(a_widget)		
		
	update_item_active_notifications_that_show_to_which_abilities_they_are_connected()
	
	# inventory buttons
	inventory_button_1.initialize(self,0)
	inventory_button_2.initialize(self,1)
	
	item_active_1.initialize(self,0)
	item_active_2.initialize(self,1)
	_on_inventory_menu_changed_inventory_items()
	
	# inventory menu
	inventory_menu.initialize(character, self)
	inventory_menu.update_inventory_gui()
	inventory_menu.hide()


	
	
	
func ability_levelup_widget_change(ability:Ability, is_increase:bool):
	if is_increase: print(ability.gui_name + " has increased")
	else: print(ability.gui_name + " has decreased")

# levelup a stat, called by the a signal from the levelup widget
# stat -stat to levelup or down
# is_increase - whether to increase or decrease the level
func stat_levelup_widget_change(levelup_widget, stat, is_increase:bool):
	character.levelup_stat(stat, is_increase)
	levelup_widget.stat_level_changed()
	
	self.emit_signal("xp_changed")
	self.emit_signal("stats_changed")

func open_inventory_item_button_pressed(button_pressed, item_slot:int):
	var inventory_menu = $inventory_menu
	inventory_menu.selected_item_slot = item_slot
	
	#remove item active if there was one
	character.items_manager.remove_item_in_slot(item_slot)
	
	inventory_menu.update_inventory_gui()	
	inventory_menu.visible = true
	

func _input(event):
	#close the menu if clicked outside of it
	if (event is InputEventMouseButton) and event.pressed:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0),rect_size).has_point(evLocal.position):
			hide()


func _on_xp_changed():
	$xp_points.text = "experience points: " + String(character.total_xp - character.used_xp)
	
func _on_ability_level_down():
	print("ability level down")

func _on_ability_level_up():
	print("ability level up")
	
func _on_inventory_menu_changed_inventory_items():
	var i1 = character.items_manager.get_item_in_slot(0)
	var i2 = character.items_manager.get_item_in_slot(1)
	
	#TODO put here code that removes previous item active - ability connections now that the item has changed
	# essentially, for each item, if it's not in the item active - ability connections, remove the connection
	
	# set both item buttons and active item buttons
	var item = i1
	var inventory_button = inventory_button_1
	var active_button = item_active_1
	for i in range(0,2):
		# take care of the inventory buttons
		if item==null: 
			inventory_button.text = "Empty"
		else: 
			inventory_button.text = item.gui_name
			
		# take care of the active item buttons			
		if item==null or !item.has_active:
			# no item was selected or item doesn't have an active
			active_button.disabled = true	
			active_button.selected_item = null
			active_button.text = "---"
			if item!=null and !item.has_active: active_button.text = "No active"
		else:
			# item has an active
			active_button.text = "Item active"
			active_button.disabled = false
			active_button.selected_item = item

		item = i2
		inventory_button = inventory_button_2
		active_button = item_active_2
		
	update_item_active_notifications_that_show_to_which_abilities_they_are_connected()
	
func choose_ability_for_item_active(selected_item, item_slot_id:int):
	#TODO add animation on items buttons to show the player he should pick them
	self.selected_item_active = [item_slot_id, selected_item]

func _on_ability_connected_to_item(ability:Ability):
	if selected_item_active==null: return  #if no active of item was selected
	character.add_ability_with_item_active_to_slot(selected_item_active[0], ability, selected_item_active[1])
	update_item_active_notifications_that_show_to_which_abilities_they_are_connected()

# update item active notifications in the menu near the abilities
# that is, show which item is connected to which ability
func update_item_active_notifications_that_show_to_which_abilities_they_are_connected():
	# remove previous connections
	for widget in $abilities.get_children():
		widget.show_item_active_connection(null)
	
	# check selected_item_active and mark connections
	var p1 = character.get_ability_with_active_item_in_slot(0)
	var p2 = character.get_ability_with_active_item_in_slot(1)
	
	for widget in abilities_panel.get_children():
		if p1!=null and widget.ability ==p1.ability and is_instance_valid(p1.item):
			widget.show_item_active_connection(p1.item)
		elif p2!=null and widget.ability ==p2.ability and is_instance_valid(p2.item):
			widget.show_item_active_connection(p2.item)
		else:
			widget.remove_item_active_connection()

func _update_stats_gui():
	stats.get_node("max_hp").text = "Max hp: " + String(character.max_hp)
	stats.get_node("hp").text = "HP: " + String(character.hp)	
	stats.get_node("attack").text = "Attack: " + String(character.base_attack_power)
	stats.get_node("ap").text = "AP: " + String(character.start_ap)
	stats.get_node("movement").text = "Movement: " + String(character.initial_movement_points)
