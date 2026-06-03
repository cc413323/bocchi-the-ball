extends Node2D

class_name Tallier

#region variables
var _tallies : Dictionary[int, float] = {}
var _tallyTarget : Bot;
var _tallyTargetModelIndex : int
var _currentScore : float
#endregion

#region rady and process
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#endregion

func update(change : float) -> void:
	_currentScore += change

func getTallyTarget() -> Bot:
	return _tallyTarget

func setTallyTarget(target: Bot, index : int) -> void:
	_tallyTarget = target
	_currentScore = 0
	_tallyTargetModelIndex = index

func endTallySession() -> void:
	_tallies[_tallyTargetModelIndex] = _currentScore
	print("score: " + str(_currentScore))

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
"""
func get_top_ten_keys() -> Array:
	# If there are fewer than 10 entries, just return all keys sorted
	if _tallies.size() == 0:
		return []

	var keys = _tallies.keys()
	# sort_custom expects a Callable; comparator will read self._tallies
	keys.sort_custom(Callable(self, "_compare_tallies_desc"))
	# return up to 10 keys
	return keys.slice(0, min(10, keys.size()))

	# comparator used by sort_custom: must return -1, 0, or 1
func _compare_tallies_desc(a, b) -> int:
	var va = _tallies.get(a, 0.0)
	var vb = _tallies.get(b, 0.0)
	if va == vb:
		return 0
	return -1 if va > vb else 1
"""
