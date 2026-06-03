extends Node2D

var scores = {
		"Alice": 120,
		"Bob": 95,
		"Charlie": 150,
		"Diana": 200,
		"Eve": 180,
		"Frank": 75,
		"Grace": 160
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print(get_tree().root.size.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func get_top_five_keys(dict: Dictionary) -> Array:
	# Sort keys by their values in descending order
	var sorted_keys = dict.keys()
	sorted_keys.sort_custom(func(a, b):
		return dict[a] > dict[b]
	)
	
	# Take top 5 keys
	var top_keys = sorted_keys.slice(0, 5)
	
	# Fill with null if less than 5
	while top_keys.size() < 5:
		top_keys.append(null)
	
	return top_keys
