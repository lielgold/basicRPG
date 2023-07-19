extends Node

const inventory_item_resource = preload("res://character/inventory_item.tscn")

onready var character = get_parent()

# add a new item and return it
func add_item(item_id:int, item_slot:int):
	var new_item = inventory_item_resource.instance()
	new_item.initialize(item_id,character,item_slot)	
	
	add_child(new_item)
	new_item.owner = character
	new_item.add_or_remove_item_passive_stats_from_character(true)
	return get_children()[-1]

# removes the item. if it wasn't found, does nothing
func remove_item(item)->void:	
	if(item==null): return
	item.add_or_remove_item_passive_stats_from_character(false)
	remove_child(item)
	item.queue_free()	

func remove_item_in_slot(item_slot:int):
	var item = get_item_in_slot(item_slot)
	if item ==null: return
	#character.remove_item_from_turn_order(item)
	remove_item(item)

func has_item(item_id:int) ->bool:
	var i = get_item(item_id)
	if(i==null): return false
	return true

func get_all_items():
	return get_children()

func get_item(item_id:int):
	for c in get_children():		
		if c.id==item_id:
			return c
	return null
	
func get_item_in_slot(item_slot:int):
	for item in get_children():
		if item.inventory_slot == item_slot:
			return item
	return null

func print_items():
	for c in get_children():
		print(c)

# Called when the node enters the scene tree for the first time.
func _ready():
	character = get_parent()
	for i in get_children(): i.character = character

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
	}
	return save_dict
