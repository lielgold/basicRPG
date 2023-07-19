extends Node

const passive_resource = preload("res://character/passive.tscn")

signal passives_changed()

onready var character = get_parent()

func add_passive(passive_id:int, is_enabled:bool = true)->void:
	for p in get_children():
		if p.id == passive_id:
			push_error(character.name + "already has passive " + p.name +". Characters can't have two of the same passives")
	
	 # create a new passive.
	var new_passive = passive_resource.instance()	
	new_passive.initialize(passive_id,is_enabled)
	add_child(new_passive)
	new_passive.owner = character
	
	emit_signal("passives_changed")

func remove_passive(passive_id:int)->void:
	var p = get_passive(passive_id)
	remove_child(p)	
	p.queue_free()
	emit_signal("passives_changed")

#get passive, return null if not found
func get_passive(passive_id) ->Passive:
	for p in get_children():		
		if p.id == passive_id:
			return p
	return null

func get_passive_id_from_name(passive_name:String):
	for p_name in Passive.PASSIVES_ID.keys():
		if passive_name==p_name:
			return Passive.PASSIVES_ID[p_name]

func get_all_active_passive()->Array:
	var output = []
	for p in get_children():
		if p.is_enabled:
			output.append(p)
	return output


# get back an array of PASSIVES_ID based on their DO_PASSIVE_AT
func get_all_passives_id_based_on_activation_time(activation_time:int)->Array:
	var output =[]
	for l in Passive.PASSIVES_INITIALIZATION_TABLE:
		if activation_time==l[2]:
			output.append(l[0])
	return output


func has_passive_and_enabled(passive_id:int)->bool:
	var p = get_passive(passive_id)
	if p !=null and p.is_enabled: return true
	return false

func reset_passives():
	for p in get_children():
		p.reset_passive()


# Called when the node enters the scene tree for the first time.
func _ready():
	character = get_parent()
	for p in get_children(): p.character = character
	connect("passives_changed",character,"_on_passives_passive_changed")
