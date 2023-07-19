extends Control

const item_reward_widget_resource = preload("res://menus/rewards_menu/item_reward_widget.tscn")
const xp_reward_widget_resource = preload("res://menus/rewards_menu/xp_reward_widget.tscn")

onready var menu_panel = $menu_panel
onready var close_menu_button = $close_menu_button
onready var item_rewards_container = $item_rewards/ScrollContainer/HBoxContainer
onready var xp_rewards_container = $xp_rewards/ScrollContainer/HBoxContainer
onready var xp_for_non_party_characters = $xp_rewards/xp_for_non_party_characters


var ow_node

# Called when the node enters the scene tree for the first time.
func _ready():
	close_menu_button.connect("pressed",self,"close_the_menu")

# ow_node - the node that gives rewards
func initialize(rewards_ow_node):
	menu_panel = $menu_panel
	close_menu_button = $close_menu_button
	item_rewards_container = $item_rewards/ScrollContainer/HBoxContainer
	xp_rewards_container = $xp_rewards/ScrollContainer/HBoxContainer
	xp_for_non_party_characters = $xp_rewards/xp_for_non_party_characters	
	
	self.ow_node = rewards_ow_node
	
	ow_node.character_id_to_get_xp_rewards
	ow_node.character_xp_rewards
	
	# do item rewards
	for c in item_rewards_container.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	
	for item_id in ow_node.item_rewards:
		# create widget
		var item_widget = item_reward_widget_resource.instance()
		item_widget.initialize(item_id)
		item_rewards_container.add_child(item_widget)
	
	# xp rewards		
	xp_for_non_party_characters.visible = false
	for c in xp_rewards_container.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()	
		
	for i in range(0, ow_node.character_id_to_get_xp_rewards.size()):
		# register the xp reward given
		var character_id = ow_node.character_id_to_get_xp_rewards[i]
		var xp_reward = ow_node.character_xp_rewards[i]
		
		var character = Globals.main_game.get_character_from_id(character_id)
		
		if character!=null:
			var xp_widget = xp_reward_widget_resource.instance()
			xp_widget.initialize(character, xp_reward)
			xp_rewards_container.add_child(xp_widget)
		else:
			xp_for_non_party_characters.visible = true


func initialize_v2(xp_rewards, item_rewards):
	menu_panel = $menu_panel
	close_menu_button = $close_menu_button
	item_rewards_container = $item_rewards/ScrollContainer/HBoxContainer
	xp_rewards_container = $xp_rewards/ScrollContainer/HBoxContainer
	xp_for_non_party_characters = $xp_rewards/xp_for_non_party_characters	
	
	# do item rewards
	for c in item_rewards_container.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	
	for item_id in item_rewards:
		# create widget
		var item_widget = item_reward_widget_resource.instance()
		item_widget.initialize(item_id)
		item_rewards_container.add_child(item_widget)
	
	# xp rewards		
	xp_for_non_party_characters.visible = false
	for c in xp_rewards_container.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()	
	
	for i in range(xp_rewards.size()):
		var character_id = xp_rewards[i][0]
		var xp = xp_rewards[i][1]
		var character = Globals.main_game.get_character_from_id(character_id)
		
		if character!=null:
			var xp_widget = xp_reward_widget_resource.instance()
			xp_widget.initialize(character, xp)
			xp_rewards_container.add_child(xp_widget)
		else:
			xp_for_non_party_characters.visible = true
	

func close_the_menu():
	hide()

func _input(event):
	#close the menu if clicked outside of it
	if (event is InputEventMouseButton) and event.pressed:
		var evLocal = make_input_local(event)
		if !Rect2(Vector2(0,0),self.rect_size).has_point(evLocal.position):
			close_the_menu()
