extends HBoxContainer



onready var ability_name = $ability_name
onready var increase = $increase
onready var decrease = $decrease
onready var item_active_connected_label = $item_active_connected
onready var charges = $charges

var character_menu
var ability:Ability


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

	

func initialize(character_menu, ability:Ability):
	ability_name = $ability_name
	increase = $increase
	decrease = $decrease	
	item_active_connected_label = $item_active_connected
	charges = $charges
	
	self.character_menu = character_menu
	self.ability = ability
	
	increase.connect("pressed",character_menu,"ability_levelup_widget_change",[ability, true])
	decrease.connect("pressed",character_menu,"ability_levelup_widget_change",[ability, false])	
	ability_name.connect("pressed",character_menu,"_on_ability_connected_to_item",[ability])	
	
	ability_name.text = ability.gui_name
	item_active_connected_label.text=""
	
	update_charges()
	

func remove_item_active_connection():
	item_active_connected_label.text = ""
	
func show_item_active_connection(item):
	if item==null: item_active_connected_label.text= ""
	else: item_active_connected_label.text= item.gui_name + " connected"
	
func update_charges():
	charges = $charges
	charges.text = "Charges: " + String(ability.charges) + " "

#func _on_ability_name_pressed():
#	character_menu._on_ability_connected_to_item(ability)
