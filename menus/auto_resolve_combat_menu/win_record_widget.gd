extends Control


var auto_resolve_combat_menu

var win_record_data


func initialize(auto_resolve_combat_menu, win_record_data):
	self.auto_resolve_combat_menu = auto_resolve_combat_menu
	self.win_record_data = win_record_data
	

func show_disabled_notification():
	$disabled_notification.visible = true

func add_character_record(character_record_widget):
	$HBoxContainer.add_child(character_record_widget)		

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("pressed",self, "chosen_record")

func chosen_record():
	auto_resolve_combat_menu.chosen_win_record(win_record_data)

func show_no_losses_message():
	$no_losses_message.show()
