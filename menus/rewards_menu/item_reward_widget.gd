extends Control


onready var item_icon = $item_icon
onready var item_name = $item_name


# Called when the node enters the scene tree for the first time.
func _ready():
	item_icon = $item_icon
	item_name = $item_name	
	
	
func initialize(item_id:int):
	item_icon = $item_icon
	item_name = $item_name	
		
	var item_data = GameData.get_item_data(item_id)
	item_name.text = item_data.gui_name	
	item_icon.texture = load(item_data.icon_path)

