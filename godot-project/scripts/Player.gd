extends CharacterBody2D

const MOVE_SPEED = 0  # Player moves forward automatically only in the web version
const EDGE_PADDING = 50

var color_index: int = 0
var can_switch: bool = true
@onready var sprite = $Sprite2D
@onready var color_indicators = $ColorIndicators

func _ready():
    position = Vector2(ProjectSettings.get_setting("display/window/size/width") / 2, 
                      ProjectSettings.get_setting("display/window/size/height") - 100)
    
    color_index = Global.player_color_index
    update_appearance()
    
    # Connect input events
    var input = InputMap.add_action("color_switch")
    InputMap.add_action("ui_accept")
    InputMap.action_add_event("ui_accept", InputEventKey.new())
    InputMap.add_action("ui_left")
    InputMap.add_action("ui_right")

func _physics_process(delta):
    # Handle horizontal movement
    var horizontal_input = Input.get_axis("ui_left", "ui_right")
    
    if horizontal_input != 0:
        velocity.x = horizontal_input * 300 * delta
        velocity.x = clamp(velocity.x, -300, 300)
    else:
        velocity.x = move_toward(velocity.x, 0, 50 * delta)
    
    # Keep player within screen bounds
    var screen_width = ProjectSettings.get_setting("display/window/size/width")
    position.x = clamp(position.x + velocity.x, EDGE_PADDING, screen_width - EDGE_PADDING)
    
    # Handle color switching
    if Input.is_action_just_pressed("color_switch") or Input.is_action_just_pressed("ui_accept"):
        switch_color()
    
    move_and_slide()

func switch_color():
    if not can_switch:
        return
    
    color_index = (color_index + 1) % Global.COLORS.size()
    Global.player_color_index = color_index
    update_appearance()
    play_switch_effect()
    
    can_switch = false
    $ColorSwitchTimer.start()

func update_appearance():
    modulate = Global.COLORS[color_index]["value"]

func play_switch_effect():
    # Simple bounce effect
    var tween = create_tween()
    tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
    tween.tween_property(sprite, "scale", Vector2(1, 1), 0.1)

func _on_color_switch_timer_timeout():
    can_switch = true

func get_color_index() -> int:
    return color_index

func set_color_index(new_index: int):
    color_index = wrapi(new_index, 0, Global.COLORS.size() - 1)
    update_appearance()

# Override default input handling
func _input(event):
    if event is InputEventMouseButton and event.is_pressed():
        switch_color()
    elif event is InputEventKey and event.pressed and event.scancode == KEY_SPACE:
        switch_color()