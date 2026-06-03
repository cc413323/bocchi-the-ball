extends CharacterBody2D

class_name Ball

var SPEED : float
var direction : Vector2 = Vector2.ZERO
var BallScene = preload("res://scenes/ball.tscn")

func initialize(startingX : float, startingY : float, spd : float, target):
	SPEED = spd
	position.x = startingX
	position.y = startingY
	
	var aimX : float = target.position.x + randf_range(-20,20)
	var aimY : float = target.position.y + randf_range(-20,20)
	var rawDir : Vector2 = Vector2(aimX,aimY) - Vector2(startingX,startingY)
	direction = rawDir.normalized()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move(delta : float) -> void:
	position += direction * SPEED * delta
