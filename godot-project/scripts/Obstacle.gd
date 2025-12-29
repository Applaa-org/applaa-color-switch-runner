extends Area2D

var color_index: int = 0
var speed: float = 3.0
var passed_player: bool = false

@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D

signal obstacle_passed
signal color_matched
signal color_mismatched

func _ready():
    # Setup collision
    body_entered.connect(_on_body_entered)
    
    # Random initial position at top of screen
    var screen_width = ProjectSettings.get_setting("display/window/size/width")
    position = Vector2(randf_range(40, screen_width - 40), -50)
    
    # Random color
    color_index = randi() % Global.COLORS.size()
    update_appearance()
    
    # Random speed
    speed = randf_range(3.0, 6.0)

func _physics_process(delta):
    # Move down
    position.y += speed * 60 * delta
    
    # Check if passed player
    if not passed_player and position.y > get_viewport_rect().size.y - 150:
        passed_player = true
        obstacle_passed.emit()
        check_color_match()
    
    # Remove off-screen
    if position.y > get_viewport_rect().size.y + 100:
        queue_free()

func update_appearance():
    if sprite:
        sprite.modulate = Global.COLORS[color_index]["value"]

func set_color_index(new_index: int):
    color_index = wrapi(new_index, 0, Global.COLORS.size() - 1)
    update_appearance()

func get_color_index() -> int:
    return color_index

func check_color_match():
    var player = get_tree().get_first_node_in_group("player")
    if player and player.get_color_index() == color_index:
        color_matched.emit()
    elif not passed_player:
        obstacle_passed.emit()

func _on_body_entered(body):
    if body.is_in_group("player"):
        var player_color = body.get_color_index()
        if player_color == color_index:
            # Colors match - player passes through
            color_matched.emit()
            body.play_switch_effect()
            queue_free()
        else:
            # Colors don't match - game over
            color_mismatched.emit()

func get_score_value() -> int:
    return 1  # Base score for passing