extends OptionButton


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var encounter_paths = [	
	"res://scenes/encounters/first_encounter.tscn",
	"res://scenes/encounters/second_encounter.tscn",
	"res://scenes/encounters/test_encounter.tscn",
	"res://scenes/encounters/hard_encounter.tscn",
	"res://scenes/encounters/another_test.tscn",
	"res://overworld.tscn"
]


# Called when the node enters the scene tree for the first time.
func _ready():
	add_item("select encounter")
	add_item("first encounter")
	add_item("second encounter")
	add_item("test encounter")
	add_item("hard encounter")
	add_item("another test encounter")
	add_item("overworld")

func _on_select_encounter_item_selected(index):
	Globals.goto_scene(encounter_paths[index-1]) # -1 because the first option in the button's option list does nothing
