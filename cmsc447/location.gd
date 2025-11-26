extends Node2D

@export var isDestination:bool = false
@export var destinationAliases:Array[String]

@export var accessibleNodes:Array[Node2D]
@export var nonAccessibleNodes:Array[Node2D]

# Will be used for the pathfinding algorithm
var parentNode
var pathLength
