extends Node2D

@onready var score_label = $CanvasLayer/UI/ScoreLabel
@onready var color_indicator = $CanvasLayer/UI/ColorIndicator
@onready var player = $Player
@onready var obstacle_timer = $ObstacleTimer
@onready var game_timer = $GameTimer

signal game_over
signal score_changed

var game_time: float = 0.0
var difficulty_level: int = 0
var last_difficulty_check: int = 0

func _ready():
    setup_game()
    connect_signals()

func setup_game():
    Global.reset_score()
    Global.is_playing = true
    
    score_label.text = "Score: " + str(Global.score)
    update_color_indicator()
    
    start_spawning()
    game_timer.start()

func connect_signals():
    player.set_physics_process(true)
    
    # Game over signal
    game_over.connect(_on_game_over)
    
    # Handle game over from collision or other game ending
    get_tree().create_timer(0.1).timeout.connect(func():
        var player_node = get_tree().get_first_node_in_group("player")
        if```gd
        if player_node and player_node.has_node("ObstacleDetector"):
            var obstacle_detector = player_node.get_node("ObstacleDetector")
            if obstacle_detector.has_method("connect_to_collision_signals"):
                obstacle_detector.connect_to_collision_signals()

func start_spawning():
    obstacle_timer.start()
    
    # Connect timer to spawn obstacles
    obstacle_timer.timeout.connect(func():
        if Global.is_playing:
            spawn_obstacle()
    )

func spawn_obstacle():
    var obstacle_scene = preload("res://scenes/Obstacle.tscn")
    var obstacle = obstacle_scene.instantiate()
    
    # Random position at top
    var screen_width = ProjectSettings.get_setting("display/window/size/width")
    obstacle.position = Vector2(randf_range(40, screen_width - 40), -50)
    
    obstacle.obstacle_passed.connect(_on_obstacle_passed)
    obstacle.color_matched.connect(_on_color_matched)
    obstacle.color_mismatched.connect(_on_color_mismatched)
    
    add_child(obstacle)

func _on_obstacle_passed():
    # Obstacle passed player safely
    Global.add_score(1)
    score_label.text = "Score: " + str(Global.score)
    score_changed.emit(Global.score)
    
    # Play sound effect (if implemented)
    # play_pass_sound()

func _on_color_matched():
    # Colors matched - bonus points
    Global.add_score(2)  # Bonus for color matching
    score_label.text = "Score: " + str(Global.score)
    score_changed.emit(Global.score)

func _on_color_mismatched():
    # Colors didn't match - game over
    game_over.emit()

func _on_game_over():
    Global.is_playing = false
    Global.set_high_score(Global.score)
    Global.save_game_data()
    
    obstacle_timer.stop()
    game_timer.stop()
    
    # Show game over screen after a short delay
    await get_tree().create_timer(0.5).timeout
    get_tree().change_scene_to_file("res://scenes/GameOverScreen.tscn")

func _on_game_timer_timeout():
    game_time += 1.0
    update_difficulty()

func update_difficulty():
    var new_difficulty = int(game_time / 10)
    if new_difficulty > difficulty_level:
        difficulty_level = new_difficulty
        
        # Increase spawn rate and speed
        obstacle_timer.wait_time = clamp(2.0 - (difficulty_level * 0.1), 0.5, 2.0)
        
        # Notify all obstacles to increase speed
        var obstacles = get_tree().get_nodes_in_group("obstacles")
        for obstacle in obstacles:
            if obstacle.has_method("increase_speed"):
                obstacle.increase_speed(1.1)

func update_color_indicator():
    var current_color = Global.COLORS[Global.player_color_index]
    color_indicator.text = "Color: " + current_color["emoji"]

func _input(event):
    if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
        get_tree().quit()