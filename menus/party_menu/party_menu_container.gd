extends HBoxContainer

const button_packed_scene = preload("res://menus/party_menu/open_character_menu_button.tscn")

# sort actions by their ap cost
class CustomCharacterSorter:
	static func sort_characters_by_id(a, b):
		if a.id < b.id: return true
		return false

# Called when the node enters the scene tree for the first time.
func _ready():	
	hide()


# start the party menu
func start_party_menu():
	show()
	for c in get_children():
		remove_child(c)
		
	# sort characters by id before creating the party menu
	var players = Globals.player_party.get_children()
	players.sort_custom(CustomCharacterSorter, "sort_characters_by_id")
	
	# add character widget to the menu by id
	for p in players:	
		for character in Globals.player_party.get_children():
			if p==character:
				var button = button_packed_scene.instance()
				button.initialize(character)
				add_child(button)
				break

		
func show_draft_buttons():
	for b in get_children():
		b.show_draft_button()
		
func hide_draft_buttons():
	for b in get_children():
		b.hide_draft_button()		
