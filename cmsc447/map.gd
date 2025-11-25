extends Node2D

@onready var map_sprite = $"Map Sprite"
@export var map_image_path = "res://2024-CAMPUS-MAP-2.jpg"
@onready var path_marker: ColorRect = $PathMarker

@onready var background_color = $"Background Color"
@onready var input_ui: ColorRect = $"Input UI"


var touch_inputs = {}

var screen_res
var initial_scale_factor
@export var max_zoom_factor = 20

func _ready():
	var map_image = load(map_image_path)
	map_sprite.texture = map_image
	
	screen_res = get_viewport_rect().size
	
	initial_scale_factor = screen_res.x / map_image.get_size().x
	map_sprite.position = screen_res / 2
	map_sprite.scale = Vector2(initial_scale_factor, initial_scale_factor)
	
	background_color.size = screen_res
	
	show_all_connections()
	#pathfind()

func _input(event):
	if event is InputEventScreenTouch and event.is_released():
		touch_inputs.erase(event.index)
	elif (event is InputEventScreenTouch or event is InputEventScreenDrag) and event.position.y > input_ui.size.y:
		touch_inputs[event.index] = event
		if event is InputEventScreenDrag:
			map_sprite.position += event.relative
		
	if (touch_inputs.has(0) 
	and touch_inputs.has(1)
	and touch_inputs[0] is InputEventScreenDrag
	and touch_inputs[1] is InputEventScreenDrag):
		var current_distance = (touch_inputs[0].position - touch_inputs[1].position).length()
		var previous_distance = ((touch_inputs[0].position - touch_inputs[0].relative) - (touch_inputs[1].position - touch_inputs[1].relative)).length()
		map_sprite.scale *= (current_distance / previous_distance)
		if map_sprite.scale.x < initial_scale_factor * max_zoom_factor and map_sprite.scale.y < initial_scale_factor * max_zoom_factor:
			var pinch_center = (touch_inputs[0].position + touch_inputs[1].position) / 2
			map_sprite.position = pinch_center + (map_sprite.position - pinch_center) * (current_distance / previous_distance)
		
	clamp_scale()
	clamp_position()

func clamp_scale():
	if map_sprite.scale.x < initial_scale_factor:
		map_sprite.scale *= initial_scale_factor / map_sprite.scale.x
	if map_sprite.scale.y < initial_scale_factor:
		map_sprite.scale *= initial_scale_factor / map_sprite.scale.y
	if map_sprite.scale.x > initial_scale_factor * max_zoom_factor:
		map_sprite.scale *= (initial_scale_factor * max_zoom_factor) / map_sprite.scale.x
	if map_sprite.scale.y > initial_scale_factor * max_zoom_factor:
		map_sprite.scale *= (initial_scale_factor * max_zoom_factor) / map_sprite.scale.y

func clamp_position():
	var image_res = map_sprite.texture.get_size()
	map_sprite.position.x = clampf(map_sprite.position.x, (screen_res.x-image_res.x*map_sprite.scale.x)/2, (screen_res.x+image_res.x*map_sprite.scale.x)/2)
	map_sprite.position.y = clampf(map_sprite.position.y, (screen_res.y-image_res.y*map_sprite.scale.y)/2, (screen_res.y+image_res.y*map_sprite.scale.y)/2)

func pathfind():
	var startLocation = $"Map Sprite/FA"
	var endLocation = $"Map Sprite/RAC"
	
	var options = []
	var visited = []
	
	# Initial path options
	for child in startLocation.get_children():
		child.pathLength = 0
		options.append(child)
		visited.append(child)
	var currentNode = null
	
	# Calculate path
	while (len(options) > 0 and (currentNode == null or currentNode.get_parent() != endLocation)):
		# Choose next node with A* algorithm
		# Actual current path length + linear distance to the End location
		currentNode = best_choice(options, endLocation)
		
		# Add neighboring nodes to options
		for neighbor in currentNode.accessibleNodes:
			if visited.count(neighbor) == 0:
				neighbor.parentNode = currentNode
				neighbor.pathLength = currentNode.pathLength + (currentNode.global_position - neighbor.global_position).length()
				options.append(neighbor)
				visited.append(neighbor)
		for neighbor in currentNode.nonAccessibleNodes:
			if visited.count(neighbor) == 0:
				neighbor.parentNode = currentNode
				neighbor.pathLength = currentNode.pathLength + (currentNode.global_position - neighbor.global_position).length()
				options.append(neighbor)
				visited.append(neighbor)
		if currentNode.get_parent().isDestination:
			for child in currentNode.get_parent().get_children():
				if child.get_script() and visited.count(child) == 0:
					child.parentNode = currentNode
					child.pathLength = currentNode.pathLength + (currentNode.global_position - child.global_position).length() + 5 # Extra value to discourage buildings
					options.append(child)
					visited.append(child)
		
		# Remove node from options
		options.erase(currentNode)
	
	# Report if a path was found
	if currentNode.get_parent() != endLocation:
		print("I couldn't find a path.")
	else:
		print("I found a path!")
		display_path(currentNode)

func best_choice(options, goal):
	if len(options) == 0:
		return null
	var best = options[0]
	for option in options:
		if (goal.global_position - option.global_position).length() + option.pathLength < (goal.global_position - best.global_position).length() + best.pathLength:
			best = option
	return best

func display_path(endNode):
	var currentNode = endNode
	while currentNode != null and currentNode.parentNode != null:
		add_path(currentNode.parentNode, currentNode)
		currentNode = currentNode.parentNode

func show_all_connections():
	for child in map_sprite.get_children():
		if ("accessibleNodes" in child and child.accessibleNodes.size() > 0):
			for neighbor in child.accessibleNodes:
				add_accessible_path(child, neighbor)
		if ("nonAccessibleNodes" in child and child.nonAccessibleNodes.size() > 0):
			for neighbor in child.nonAccessibleNodes:
				add_path(child, neighbor)
		if child.get_child_count() > 0:
			for grandchild in child.get_children():
				if ("accessibleNodes" in grandchild and grandchild.accessibleNodes.size() > 0):
					for neighbor in grandchild.accessibleNodes:
						add_accessible_path(grandchild, neighbor)
				if ("nonAccessibleNodes" in grandchild and grandchild.nonAccessibleNodes.size() > 0):
					for neighbor in grandchild.nonAccessibleNodes:
						add_path(grandchild, neighbor)

func add_path(firstNode, secondNode):
	if (secondNode != null):
		var new_path = path_marker.duplicate()
		new_path.color = Color.RED
		firstNode.add_child(new_path)
		new_path.position = Vector2.ZERO
		new_path.rotation = (firstNode.global_position - secondNode.global_position).angle() + PI
		new_path.size = Vector2((firstNode.global_position - secondNode.global_position).length() / initial_scale_factor, 5)

func add_accessible_path(firstNode, secondNode):
	if (secondNode != null):
		var new_path = path_marker.duplicate()
		new_path.color = Color.BLUE
		firstNode.add_child(new_path)
		new_path.position = Vector2.ZERO
		new_path.rotation = (firstNode.global_position - secondNode.global_position).angle() + PI
		new_path.size = Vector2((firstNode.global_position - secondNode.global_position).length() / initial_scale_factor, 5)
