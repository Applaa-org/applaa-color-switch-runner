extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var restart_button = $VBoxContainer/RestartButton
@onready var main_menu_button = $VBoxContainer/MainMenuButton
@onready var close_button = $VBoxContainer/CloseButton

func _ready():
    score_label.text = "Score: " + str(Global.score)
    
    restart_button.pressed.connect(_on_restart_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)
    close_button.pressed.connect(_on_close_pressed)

func _on_restart_pressed():
    Global.reset_score()
    get_tree().reload_current_scene()

func _on_main_menu_pressed():
    Global.reset_score()
    get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

func _on_close_pressed():
    get_tree().quit()