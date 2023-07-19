extends Control

onready var nodes = $nodes

# Called when the node enters the scene tree for the first time.
func _ready():
	for node in nodes.get_children():
		node.map = self
