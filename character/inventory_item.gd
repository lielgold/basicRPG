extends Node

class_name InventoryItem

var ITEMS_ID = GameData.ITEMS_ID
var CHARACTER_STATS = GameData.CHARACTER_STATS
var DO_ITEM_AT = GameData.DO_ITEM_AT
var ALL_ITEMS_DATA = GameData.ALL_ITEMS_DATA

var character
export var id:int
export var gui_name:String
export var passive_stats:Dictionary
export var is_enabled:bool
export var inventory_slot:int

# active variables
export var has_active:bool
export var do_item_at:int
export var charges :int

func initialize(item_id:int, character, slot:int, is_enabled:bool=true):
	self.character = character
	self.is_enabled = is_enabled
	var item_data = GameData.get_item_data(item_id)
	self.id = item_data.id
	self.gui_name = item_data.gui_name
	self.passive_stats = item_data.passive_stats
	self.inventory_slot = slot
	
	# set active effect of the item
	if(item_data.active==null): 
		self.has_active = false
		self.do_item_at = DO_ITEM_AT.NO_ACTIVE
		self.charges = NAN		
	else: 
		has_active = true
		self.do_item_at = item_data.active.do_item_at
		self.charges = item_data.active.charges

#add_item==true  -> add item passive stats from character
#add_item==false  -> remove item passive stats from character
func add_or_remove_item_passive_stats_from_character(add_item:bool):
	# on add we do stat * 1
	# on remove we do stat * -1 to remove the stats the character got	
	var mult = 1
	if !add_item: mult = -1	

	for k in passive_stats.keys():
		if (k==CHARACTER_STATS.max_hp): 
			character.max_hp += passive_stats[CHARACTER_STATS.max_hp] * mult
		elif (k==CHARACTER_STATS.base_attack):
			character.base_attack_power += passive_stats[CHARACTER_STATS.base_attack] * mult
		elif (k==CHARACTER_STATS.damage_reduction): 
			character.damage_reduction += passive_stats[CHARACTER_STATS.damage_reduction] * mult
		else:
			push_error(String(k) + " is not a valid key for item.passive_stats")

# do the active of the item
# the do do_item_at_arg should be taken from DO_ITEM_AT. It's used inside the item active functions to decide whether to do anything.
func do_item_active(do_item_at_time):
	# if item has no active, or if it's done at a different time, or if it uses charges and they ran out - than don't do nothing
	if has_active==false or (!is_nan(charges) and charges<=0): return	
	
	if !is_nan(charges): charges -=1
	match id:
		ITEMS_ID.DAGGER: dagger_do_function(do_item_at_time)
		ITEMS_ID.HEALING_CUP: healing_cup_do_function(do_item_at_time)

func dagger_do_function(do_item_at_time):
	if do_item_at_time==GameData.DO_ITEM_AT.TURN_END:
		print("inside dagger_do_function")

func healing_cup_do_function(do_item_at_time):	
	if do_item_at_time==GameData.game_data.DO_ITEM_AT.TURN_START:
		print("inside healing_cup_do_function")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _to_string():
	return character.name + " has item " + gui_name 

# Used for saving the node. returns a dict of the node's features to be saved. 
func save()->Dictionary:
	var save_dict = {
		"filename" : get_filename(),
		"parent" : get_parent().get_path(),
		"id" : id,
		"gui_name" : gui_name,
		"passive_stats" : passive_stats,
		"is_enabled" : is_enabled,
		"has_active" : has_active,
		"do_item_at" : do_item_at,
		"charges" : charges,
		"inventory_slot" : inventory_slot,
	}
	return save_dict
