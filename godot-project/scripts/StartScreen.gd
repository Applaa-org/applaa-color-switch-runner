extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var close_button = $VBoxContainer/CloseButton
@onready var name_input = $VBoxContainer/PlayerNameInput
@onready var high_score_label = $VBoxContainer/HighScoreLabel
@onready var leaderboard_container = $VBoxContainer/LeaderboardContainer
@onready var top_scores_list = $VBoxContainer/LeaderboardContainer/MarginContainer/TopScoresList

func _ready():
    start_button.pressed.connect(_on_start_pressed)
    close_button.pressed.connect(_on_close_pressed)
    name_input.text_submitted.connect(_on_name_submitted)
    
    # Set up message listener
    if JavaScriptBridge:
        JavaScriptBridge.eval("
            window.addEventListener('message', function(event) {
                if (event.data.type === 'applaa-game-data-loaded') {
                    window.showLeaderboardData = event.data.data;
                }
            });
        ")
    
    # Request game data
    request_game_data()
    
    update_high_score_display()

func _on_start_pressed():
    var player_name = name_input.text.trim()
    if player_name.is_empty():
        player_name = "Player"
    
    Global.player_name = player_name
    
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_close_pressed():
    get_tree().quit()

func _on_name_submitted(text: String):
    if not text.is_empty():
        _on_start_pressed()

func update_high_score_display():
    high_score_label.text = "High Score: " + str(Global.high_score)
    high_score_label.visible = true

func request_game_data():
    if JavaScriptBridge:
        JavaScriptBridge.eval("
            window.parent.postMessage({
                type: 'applaa-game-load-data',
                gameId: 'color-switch-runner'
            }, '*');
        ")
        
        # Process any loaded data
        var loaded_data = JavaScriptBridge.eval("window.showLeaderboardData || null")
        if loaded_data:
            display_leaderboard(JSON.parse(loaded_data))

func display_leaderboard(data: Dictionary):
    if not data.has("scores"):
        return
    
    leaderboard_container.visible = true
    var scores = data["scores"]
    
    # Clear existing items
    for child in top_scores_list.get_children():
        child.queue_free()
    
    # Display top 5 scores
    var count = min(5, scores.size())
    for i in count:
        var score_data = scores[i]
        var label = Label.new()
        label.text = str(i + 1) + ". " + str(score_data["playerName"]) + " - " + str(score_data["score"])
        top_scores_list.add_child(label)
        
        if i == 0:  # Highlight top score
            label.add_theme_color_override("font_color", Color(1, 0.84, 0))
            label.add_theme_font_size_override("font_size", 16)