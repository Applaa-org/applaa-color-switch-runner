extends Control

@onready var final_score_label = $VBoxContainer/FinalScoreLabel
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var new_high_score_label = $VBoxContainer/NewHighScoreLabel
@onready var restart_button = $VBoxContainer/RestartButton
@onready var main_menu_button = $VBoxContainer/MainMenuButton

func _ready():
    # Initialize high score display immediately to 0
    update_high_score_display(0)
    
    restart_button.pressed.connect(_on_restart_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)
    
    # Display results after short delay
    await get_tree().create_timer(0.1).timeout
    display_results()

func display_results():
    var final_score = Global.score
    var is_high_score = final_score > Global.high_score
    
    final_score_label.text = "Score: " + str(final_score)
    high_score_label.text = "High Score: " + str(max(final_score, Global.high_score))
    
    # Show/hide new high score notification
    new_high_score_label.visible = is_high_score
    
    # Update displayed high score
    update_high_score_display(max(final_score, Global.high_score))

func update_high_score_display(score: int):
    high_score_label.text = "High Score: " + str(score)
    high_score_label.visible = true

func _on_restart_pressed():
    # Reset and restart game
    Global.reset_score()
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_main_menu_pressed():
    # Return to start screen
    get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")