extends Control

class_name ActionButton

const TARGETING_TYPE = preload("res://character/ability_v2.gd").TARGETING_TYPE

const right_arrow_resource = preload("res://assets/targeting_type/right_arrow.png")
const left_arrow_resource = preload("res://assets/targeting_type/left_arrow.png")
const buff_resource = preload("res://assets/targeting_type/buff.png")
const all_resource = preload("res://assets/targeting_type/all.png")
const all_allies_resource = preload("res://assets/targeting_type/all_allies.png")
const all_enemies_resource = preload("res://assets/targeting_type/all_enemies.png")
const other_resource = preload("res://assets/targeting_type/other.png")
const status_effect_indicator_resource = preload("res://character/status_effects_indicator/status_effects_indicator.tscn")

onready var select_action_button = $VBoxContainer_bottom_elements/select_action_container/select_action_button

onready var portait = $VBoxContainer_bottom_elements/CenterContainer/portait
#onready var team_indicator = $VBoxContainer_bottom_elements/select_action_container/select_action_button/team_indicator
onready var its_my_turn_indicator = $its_my_turn_indicator
onready var has_played_indicator = $has_played_indicator

onready var target_indicator = $VBoxContainer_bottom_elements/CenterContainer/portait/target_indicator
onready var name_of_character = $name_of_character
#onready var highlight_for_selection = $VBoxContainer_bottom_elements/select_action_container/select_action_button/highlight_for_selection
onready var died_indicator = $VBoxContainer_bottom_elements/CenterContainer/portait/died_indicator
onready var targeting_type_indicator = $VBoxContainer_bottom_elements/select_action_container/select_action_button/targeting_type_indicator
onready var status_effects = $status_effects

onready var item_active = $VBoxContainer/item_active
onready var charges_remaining = $VBoxContainer_bottom_elements/select_action_container/charges_remaining
onready var ap_cost = $VBoxContainer/ap_cost
onready var ability_speed = $speed_indicator_background/ability_speed2
onready var attack_speed = $attack_indicator_background/ability_attack


onready var left_buttons_container = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_left
onready var move_left = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_left/move_left
onready var move_right = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_right/move_right

onready var right_buttons_container = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_right
onready var charges_move_left = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_left/charges_move_left
onready var charges_move_right = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_right/charges_move_right

onready var change_ability_direction = $VBoxContainer_bottom_elements/HBoxContainer/change_ability_direction
onready var health_bar = $VBoxContainer_bottom_elements/health_bar

onready var status_effects_container = $status_effects_container


var combat_control
var action_matrix
var character:Character
var combat_ability:Ability

var _distance_from_character_sort_argument := 0 # used only to sort with 
var index_relative_to_start_position := 0 # used to undo changes the number of charges used when moving the butotn. So the button left costs one charge, and moving it right afterwards gives back 1 charges
var player_changed_direction :=false # used to undo changes to the number of charges used when switching ability direction
var item = null # this is the inventory item attached to this button's ability. It should stay null if the item has no active.
var combat_action_speed :int

var targeting_type

var its_my_turn:=false
var did_turn:=false

func initialize(combat_control, character :Character, ability_to_use:Ability, use_regular_attack:=false):
	select_action_button = $VBoxContainer_bottom_elements/select_action_container/select_action_button
	portait = $VBoxContainer_bottom_elements/CenterContainer/portait
#	team_indicator = $VBoxContainer_bottom_elements/select_action_container/select_action_button/team_indicator
	ap_cost = $VBoxContainer/ap_cost
	its_my_turn_indicator = $its_my_turn_indicator
	has_played_indicator = $has_played_indicator
	charges_remaining = $VBoxContainer_bottom_elements/select_action_container/charges_remaining	
	item_active = $VBoxContainer/item_active
	target_indicator = $VBoxContainer_bottom_elements/CenterContainer/portait/target_indicator
	name_of_character = $name_of_character
#	highlight_for_selection = $VBoxContainer_bottom_elements/select_action_container/select_action_button/highlight_for_selection
	died_indicator = $VBoxContainer_bottom_elements/CenterContainer/portait/died_indicator
	targeting_type_indicator = $VBoxContainer_bottom_elements/select_action_container/select_action_button/targeting_type_indicator
	ability_speed = $speed_indicator_background/ability_speed2
	attack_speed = $attack_indicator_background/ability_attack
	status_effects = $status_effects
	
	move_left = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_left/move_left
	move_right = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_right/move_right
	charges_move_left = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_left/charges_move_left
	charges_move_right = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_right/charges_move_right
	change_ability_direction = $VBoxContainer_bottom_elements/HBoxContainer/change_ability_direction
	health_bar = $VBoxContainer_bottom_elements/health_bar
	status_effects_container = $status_effects_container
	left_buttons_container = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_left
	right_buttons_container = $VBoxContainer_bottom_elements/HBoxContainer/VBoxContainer_right
	
	self.combat_control = combat_control
	self.action_matrix = combat_control.action_matrix
	self.character = character
	self.combat_ability = ability_to_use
	self.targeting_type = ability_to_use.target_type
	
	select_action_button.connect("item_selected",self,"switch_to_other_action")
	
	select_action_button.add_item("Select ability:")
	var index = 1
	for ability in character.abilities_manager.get_all_abilities():
		select_action_button.add_item(ability.gui_name, ability.ability_id)
		select_action_button.set_item_tooltip(index, ability.gui_name)
		index+=1
	
	
	# set gui according to the ability and the character
	select_action_button.text = self.combat_ability.gui_name
	portait.texture = character.portrait
	self.name_of_character.text = character.character_name
	combat_action_speed = self.combat_ability.speed
	update_speed_indicator()
	update_attack_indicator()
		
	if !character.part_of_player_party:
		select_action_button.hint_tooltip = combat_ability.gui_name	
		if !Globals.DEBUG: 
			disable_action_selection()
			hide_change_direction()
			hide_left_move_buttons()
			hide_right_move_buttons()
			
	
	# set button color according to the character's team
#	if character.team == Globals.TEAMS.ENEMY: 
#		team_indicator.modulate = Color("ffd6d6")
#	elif character.team == Globals.TEAMS.PLAYER: 
#		team_indicator.modulate = Color("ccffa8")
#	team_indicator.modulate.a = 0.15
	
	# set indicators
	update_ap()
	update_charges_indicator()
	
	if self.item !=null: item_active.text = "Item: " + self.item.gui_name # TODO check this works after I add item to the initialization (or remove it if it's not neccesary)
	else: item_active.text = ""
	
	# set targeting_type_indicator
	update_targeting_type_indicator()
	
	# hide indicators that shouldn't be visiable at the start
	its_my_turn_indicator.visible = false
	target_indicator.visible = false
#	highlight_for_selection.visible = false
	died_indicator.visible = false	
	
	# status effects
	show_major_status_effect()
	for s in status_effects_container.get_children():
		status_effects_container.remove_child(s)
	
	# movement buttons	
	move_left.connect("pressed",action_matrix,"move_action_button", [self,false,false])
	move_right.connect("pressed",action_matrix,"move_action_button", [self,true,false])
	charges_move_left.connect("pressed",action_matrix,"move_action_button", [self,false,true])
	charges_move_right.connect("pressed",action_matrix,"move_action_button", [self,true,true])
	change_ability_direction.connect("pressed",self,"change_direction_of_ability")
	
	health_bar.initialize(character)
	update_healthbar()
	
	# turn indicator
	show_has_played_indicator()



# Adds an item to this action. If the item has no active than this function sets it as null, 
# as the item was already added to the character's inventory. The item is only used in the ability for 
# it's active component
func add_item_to_action(item_to_add)->void:
	if item_to_add==null: 
		self.item = null
	elif item_to_add.has_active==false:
		self.item = null
	else:		
		item = item_to_add
		item_active.text = item.gui_name

# called after selecting a different action, switches to another action
func switch_to_other_action(index_of_new_action):
	var new_action_id = select_action_button.get_item_id(index_of_new_action)
	combat_control.switch_action_button_to_new_action_v2(self, character, new_action_id)
	action_matrix.update_turn_indicators()

func update_targeting_type_indicator():	
	match targeting_type:
		Ability.TARGETING_TYPE.NONE:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/none.png")
		Ability.TARGETING_TYPE.SELF:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/self.png")
		Ability.TARGETING_TYPE.ALL_ALLIES:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/all_allies.png")		
		Ability.TARGETING_TYPE.ALL_ENEMIES: 
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/all_enemies.png")
		Ability.TARGETING_TYPE.EVERYONE: 
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/everyone.png")
		Ability.TARGETING_TYPE.LOWEST_HP_ENEMY:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/lowest_hp.png")
		Ability.TARGETING_TYPE.SLOWEST_ENEMY:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/slowest.png")
		Ability.TARGETING_TYPE.FIRST_RIGHT_ENEMY: 
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/first_right_enemy.png")			
		Ability.TARGETING_TYPE.FIRST_LEFT_ENEMY: 
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/first_left_enemy.png")
		Ability.TARGETING_TYPE.RIGHT_ENEMY_COLUMN:  
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/right_enemy_column.png")
		Ability.TARGETING_TYPE.LEFT_ENEMY_COLUMN:   
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/left_enemy_column.png")
		Ability.TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/right_character.png")
		Ability.TARGETING_TYPE.FIRST_LEFT_CHARACTER_IN_SAME_ROW:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/left_character.png")
		Ability.TARGETING_TYPE.RIGHT_COLUMN:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/char_right_column.png")
		Ability.TARGETING_TYPE.LEFT_COLUMN:
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/char_left_column.png")
		Ability.TARGETING_TYPE.CHARACTERS_ON_BOTH_SIDES:				
			targeting_type_indicator.texture = preload("res://assets/targeting_type2/char_on_both_sides.png")
					
		_:
			targeting_type_indicator.texture = other_resource

# change the direction of the targeting from left to right, up to down, and so forth
func switch_targeting_direction():
	match targeting_type:
		TARGETING_TYPE.FIRST_LEFT_ENEMY: 
			targeting_type = TARGETING_TYPE.FIRST_RIGHT_ENEMY
		TARGETING_TYPE.FIRST_RIGHT_ENEMY: 
			targeting_type = TARGETING_TYPE.FIRST_LEFT_ENEMY
		TARGETING_TYPE.RIGHT_ENEMY_COLUMN: 		
			targeting_type = TARGETING_TYPE.LEFT_ENEMY_COLUMN
		TARGETING_TYPE.LEFT_ENEMY_COLUMN: 
			targeting_type = TARGETING_TYPE.RIGHT_ENEMY_COLUMN
		TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW: 
			targeting_type = TARGETING_TYPE.FIRST_LEFT_CHARACTER_IN_SAME_ROW
		TARGETING_TYPE.FIRST_LEFT_CHARACTER_IN_SAME_ROW: 
			targeting_type = TARGETING_TYPE.FIRST_RIGHT_CHARACTER_IN_SAME_ROW
		TARGETING_TYPE.RIGHT_COLUMN: 
			targeting_type = TARGETING_TYPE.LEFT_COLUMN			
		TARGETING_TYPE.LEFT_COLUMN: 
			targeting_type = TARGETING_TYPE.RIGHT_COLUMN

# change the direction of the targeting from left to right, up to down, and so forth
# does nothing if there are no charges left
# and than change the action matrix accordingly
# this sets the initial direction of the ai ability, which is the opposite of the direction of the play
# so it's flipped using this function
# change_initial_ai_direction - This sets the initial direction of ai actions. By defualt actions point to the right. For ai they need to point to the left. 
func change_direction_of_ability(change_initial_ai_direction:=false):		
	var did_change_direction = true
	# this code calculates the cost of switching direction, it's irrelvant when setting the initial ability direction of the ai
	if change_initial_ai_direction:
		pass
	else:
		if player_changed_direction==false and combat_ability.charges >0:
			combat_ability.charges -=1
			player_changed_direction =true
		elif player_changed_direction:
			combat_ability.charges +=1
			player_changed_direction =false		
		else: 
			did_change_direction = false	
	
	# change the direction of the ability
	if did_change_direction or change_initial_ai_direction:
		switch_targeting_direction()
		if portait.flip_h: 
			portait.flip_h=false
		else: 
			portait.flip_h=true	
	
	# update gui
	update_targeting_type_indicator()
	update_charges_indicator()	
	
	if !change_initial_ai_direction: # this avoids a bug when showing the turn indicator in the initial ai pass, and it's irrelevent anyway
		action_matrix.update_turn_indicators()
		

# reset the start position of the button
# called after changing the turn when the plauer can no longer undo his actions
func reset_start_position():
	index_relative_to_start_position = 0
	player_changed_direction = false	

func get_max_hp()->int:
	return character.get_max_hp()

func update_healthbar():
	health_bar.update_healthbar(character.hp, character.temp_hp)

# update the status effect indicators
# can be optimized if needed by not removing everything every time, but updating existing indicators - probably compeletely pointless
func updates_status_effects()->void:
	for c in status_effects_container.get_children():
		status_effects_container.remove_child(c)
		
	for se in character.status_effects.status_effects_dict.values():
		# create a new indicator
		var new_se_indicator = status_effect_indicator_resource.instance()
		new_se_indicator.initialize(se)
		status_effects_container.add_child(new_se_indicator)


# update the ap indicator
func update_ap()->void:
	# set indicators
	ap_cost.text = "Ap: " + String(combat_ability.ap_cost)	

func hide_its_my_turn_indicator()->void:
	its_my_turn_indicator.visible = false
	
func show_its_my_turn_indicator()->void:
	its_my_turn_indicator.visible = true	

func hide_has_played_indicator()->void:
	has_played_indicator.visible = false
	
func show_has_played_indicator()->void:
	has_played_indicator.visible = true	

func show_target_indicator()->void:
	target_indicator.show()
	
func hide_target_indicator()->void:
	target_indicator.hide()

#func show_highlight_for_selection()->void:
#	highlight_for_selection.visible = true

#func hide_highlight_for_selection()->void:
#	highlight_for_selection.visible = false

func show_character_died()->void:
	select_action_button.disabled = true
	select_action_button.modulate.a = 0.8
	died_indicator.visible = true
	
func show_major_status_effect()->void:
	status_effects.text = ""
	
	status_effects.text = "Status effects: \n"
	for s in character.status_effects.status_effects_dict.values():
		status_effects.text += s.gui_name + " - " + String(s.duration) + "\n"	

# hide / show the right / left  movement buttons, used when the button is at the right / left edge of the matrix
func hide_right_move_buttons()->void:
	right_buttons_container.visible=false

func show_right_move_buttons()->void:	
	# don't show button of enemies when not in debug mode
	if !character.part_of_player_party and !Globals.DEBUG:
		return
	right_buttons_container.visible=true
	

func hide_left_move_buttons()->void:
	left_buttons_container.visible=false

func show_left_move_buttons()->void:
	# don't show button of enemies when not in debug mode
	if !character.part_of_player_party and !Globals.DEBUG:
		return	
	left_buttons_container.visible=true

func show_change_direction()->void:
	# don't show button of enemies when not in debug mode
	if !character.part_of_player_party and !Globals.DEBUG:
		return	
	change_ability_direction.visible=true
	
func hide_change_direction()->void:
	change_ability_direction.visible=false

func disable_action_selection()->void:
	select_action_button.disabled = true

func enable_action_selection()->void:
	select_action_button.disabled = false

func update_charges_indicator()->void:
	if combat_ability.charges != Ability.CHARGES_NOT_USED: 		
		charges_remaining.text = String(combat_ability.charges)
	else:
		charges_remaining.text = "-"

func update_speed_indicator()->void:
	ability_speed.text = String(combat_action_speed)

func update_attack_indicator()->void:
	attack_speed.text = String(character.attack_power)

# might want to change it later on to something more complicated that takes buffs and debuffs into account
func get_combat_action_speed()->int:
	return combat_action_speed

func did_turn():
	its_my_turn=false
	did_turn=true
