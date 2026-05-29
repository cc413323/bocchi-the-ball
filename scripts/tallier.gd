extends Node2D

class_name Tallier

var _tallies : Dictionary[int, float]
var _tallyTarget : Bot;
var _tallyTargetModelIndex : int
var _currentScore : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update(change : float) -> void:
	_currentScore += change

func getTallyTarget() -> Bot:
	return _tallyTarget

func setTallyTarget(target: Bot, index : int) -> void:
	_tallyTarget = target
	_tallyTargetModelIndex = index

func endTallySession() -> void:
	_tallies[_tallyTargetModelIndex] = _currentScore
	
	_tallyTarget = null
	_tallies = {}
	_currentScore = 0;
	_tallyTargetModelIndex = -1
	
func get_top_ten_keys() -> Array:
	var data = _tallies
	var keys = data.keys()
	
	# Start with first 10 keys
	var top_keys := keys.slice(0, 10)
	
	for i in range(10, keys.size()):
		var current_key = keys[i]
		
		# Find smallest value among current top keys
		var smallest_index := 0
		
		for j in range(1, 10):
			if data[top_keys[j]] < data[top_keys[smallest_index]]:
				smallest_index = j
				
		# Replace if current value is larger
		if data[current_key] > data[top_keys[smallest_index]]:
			top_keys[smallest_index] = current_key

	return top_keys
