extends Node2D

@onready var map_sprite = $"Map Sprite"
@export var map_image_path = "res://2024-CAMPUS-MAP-2.jpg"

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
