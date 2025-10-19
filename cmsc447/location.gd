extends Node2D

@export var isDestination:bool = false
@export var accessibleNodes:Array[Node2D]
@export var nonAccessibleNodes:Array[Node2D]

# Will be used for the pathfinding algorithm
var parentNode
var pathLength

func _ready():
	if isDestination:
		var destinationIcon = get_tree().root.get_node("Node2D/Map/Destination Icon")
		var newDestinationIcon = destinationIcon.duplicate()
		if newDestinationIcon.get_parent():
			newDestinationIcon.get_parent().remove_child(newDestinationIcon)
		add_child(newDestinationIcon)
		newDestinationIcon.global_position = global_position
