extends Node

# Game constants
const COLORS = [
    {"name": "red", "value": Color(1, 0.27, 0.34), "emoji": "🔴"},
    {"name": "blue", "value": Color(0.18, 0.53, 0.87), "emoji": "🔵"},
    {"name": "yellow", "value": Color(0.94, 0.77, 0.06), "emoji": "🟡"},
    {"name": "green", "value": Color(0.15, 0.68, 0.38), "emoji": "🟢"}
]

# Game state
var score: int = 0
var high_score: int = 0
var is_playing: bool = false
var player_name: String = "Player"
var player_color_index: int = 0

func _ready():
    load_saved_data()
    # Save high score when app quits
    get_tree().get_root().gui_visibility_changed.connect(_on_app_quit)

func load_saved_data():
    # Load from localStorage if available
    if JavaScriptBridge:
        var saved = JavaScriptBridge.eval("localStorage.getItem('colorSwitchRunner_data') || '{}'")
        var data = JSON.parse(saved)
        if data.has("highScore"):
            high_score = int(data["highScore"])
        if data.has("lastPlayerName"):
            player_name = str(data["lastPlayerName"])

func save_game_data():
    if JavaScriptBridge:
        var data = {
            "highScore": high_score,
            "scores": [{"playerName": player_name, "score": score}],
            "lastPlayerName": player_name,
            "gameId": "color-switch-runner"
        }
        JavaScriptBridge.eval("localStorage.setItem('colorSwitchRunner_data', JSON.stringify(arguments[0]));", [data])
        
        # Save to parent for leaderboard
        JavaScriptBridge.eval("window.parent.postMessage({type: 'applaa-game-save-score', gameId: 'color-switch-runner', playerName: arguments[0], score: arguments[1]}, '*');", [player_name, score])

func reset_score():
    score = 0
    player_color_index = 0

func add_score(points: int):
    score += points

func set_high_score(new_score: int):
    if new_score > high_score:
        high_score = new_score

func _on_app_quit():
    save_game_data()