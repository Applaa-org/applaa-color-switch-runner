extends Node

func _ready():
    # Initialize global variables
    Engine.max_fps = 60
    # Load start screen
    get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

func _input(event):
    if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
        get_tree().quit()