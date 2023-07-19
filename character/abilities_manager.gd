extends Node


onready var character = get_parent()

const ability_resource = preload("res://character/ability.tscn")
const ability_script_resource = preload("res://character/ability_v2.gd")

# add new ability by id and get it back
func add_ability_by_id(ability_id:int)->Ability:
	var new_ability = ability_resource.instance()
	new_ability.initialize(ability_id)
	
	add_child(new_ability)
	new_ability.owner = character
	return new_ability
	
# add new ability and get it back
func add_ability(ability:Ability)->Ability:
	add_child(ability)
	ability.owner = character
	return ability

# get ability by ability_id
func get_ability(ability_id:int) ->Ability:
	for c in get_children():		
		if c.ability_id==ability_id:
			return c
	return null


# remove ability
func remove_ability(ability:Ability)->void:
	remove_child(ability)

# remove ability and free it
func remove_last_ability()->void:
	var last:Node
	for c in get_children():
		last=c	
	remove_child(last)
	last.queue_free()
	

func get_all_abilities():
	return get_children()

# full_reset - completely reset ability. reset charges back to full.
func reset_abilities(full_reset:=false):
	for a in get_children():
		a.reset_ability(full_reset)

# get the the regular attack of a character
# should never be called if the character doesn't have a regular attack -> error
func get_regular_attack()->int:	
	for c in get_children():		
		if c.ability_id==ability_script_resource.ABILITIES_ID.REGULAR_ATTACK:
			return c		
	push_error("get_index_of_regular_attack called on a character without a regular attack")
	return -1


# Called when the node enters the scene tree for the first time.
func _ready():
	character = get_parent()
	for a in get_children(): a.character = character
		 
