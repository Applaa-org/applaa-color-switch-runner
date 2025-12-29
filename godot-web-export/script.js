// Game configuration
const CONFIG = {
    CANVAS_WIDTH: 800,
    CANVAS_HEIGHT: 600,
    PLAYER_SIZE: 30,
    PLAYER_SPEED: 2,
    OBSTACLE_SPEED_MIN: 3,
    OBSTACLE_SPEED_MAX: 8,
    OBSTACLE_SPAWN_RATE: 0.02,
    COLORS: [
        { name: 'red', value: '#FF4757', emoji: '🔴' },
        { name: 'blue', value: '#2E86DE', emoji: '🔵' },
        { name: 'yellow', value: '#F1C40F', emoji: '🟡' },
        { name: 'green', value: '#27AE60', emoji: '🟢' }
    ]
};

// Game state variables
let gameState = {
    isPlaying: false,
    score: 0,
    highScore: 0,
    playerColorIndex: 0,
    obstacles: [],
    lastSpawn: 0,
    obstacleSpeed: CONFIG.OBSTACLE_SPEED_MIN,
    spawnRate: CONFIG.OBSTACLE_SPAWN_RATE,
    player: {
        x: CONFIG.CANVAS_WIDTH / 2,
        y: CONFIG.CANVAS_HEIGHT - 80,
        radius: CONFIG.PLAYER_SIZE / 2,
        colorIndex: 0
    }
};

// Canvas and context
let canvas, ctx;
let animationId;

// Game data for localStorage
let gameData = {
    playerName: '',
    highScore: 0,
    scores: [],
    lastPlayerName: '',
    gameProgress: {}
};

// Initialize game
function init() {
    // Get DOM elements
    canvas = document.getElementById('gameCanvas');
    ctx = canvas.getContext('2d');
    
    // Set canvas size
    canvas.width = CONFIG.CANVAS_WIDTH;
    canvas.height = CONFIG.CANVAS_HEIGHT;
    
    // Load saved game data
    loadGameData();
    
    // Setup event listeners
    setupEventListeners();
    
    // Show start screen
    showScreen('startScreen');
    
    // Initialize high score display
    updateHighScoreDisplay();
    
    // Request game data from parent
    requestGameData();
}

// Load game data from localStorage
function loadGameData() {
    try {
        const saved = localStorage.getItem('colorSwitchRunner_data');
        if (saved) {
            const parsed = JSON.parse(saved);
            gameData = { ...gameData, ...parsed };
            gameState.highScore = gameData.highScore || 0;
        }
    } catch (e) {
        console.log('No saved data found');
    }
}

// Save game data to localStorage
function saveGameData() {
    localStorage.setItem('colorSwitchRunner_data', JSON.stringify(gameData));
    
    // Also save to parent if available
    try {
        window.parent.postMessage({
            type: 'applaa-game-save-score',
            gameId: 'color-switch-runner',
            playerName: gameData.playerName,
            score: gameState.score
        }, '*');
    } catch (e) {
        console.log('Parent save failed, using localStorage only');
    }
}

// Request game data from parent (for high scores, etc.)
function requestGameData() {
    try {
        window.parent.postMessage({
            type: 'applaa-game-load-data',
            gameId: 'color-switch-runner'
        }, '*');
    } catch (e) {
        console.log('Parent game data request failed');
    }
}

// Setup event listeners
function setupEventListeners() {
    // Start screen
    document.getElementById('startButton').addEventListener('click', startGame);
    document.getElementById('closeButton').addEventListener('click', closeGame);
    document.getElementById('playerNameInput').addEventListener('keypress', (e) => {
        if (e.key === 'Enter') startGame();
    });
    
    // Game over screen
    document.getElementById('restartButton').addEventListener('click', restartGame);
    document.getElementById('mainMenuButton').addEventListener('click', () => {
        showScreen('startScreen');
    });
    
    // Game controls
    canvas.addEventListener('click', handlePlayerInput);
    document.addEventListener('keydown', (e) => {
        if (e.code === 'Space') {
            e.preventDefault();
            if (gameState.isPlaying) {
                handlePlayerInput();
            }
        }
    });
    
    // Listen for parent messages
    window.addEventListener('message', (event) => {
        if (event.data.type === 'applaa-game-data-loaded') {
            const loadedData = event.data.data;
            if (loadedData && loadedData.scores) {
                displayLeaderboard(loadedData.scores);
            }
        }
    });
}

// Handle player input (color switching)
function handlePlayerInput() {
    if (gameState.isPlaying) {
        gameState.playerColorIndex = (gameState.playerColorIndex + 1) % CONFIG.COLORS.length;
        gameState.player.colorIndex = gameState.playerColorIndex;
        
        // Color change animation feedback
        animateColorChange();
    }
}

// Animate color change with visual feedback
function animateColorChange() {
    canvas.style.transform = 'scale(1.02)';
    setTimeout(() => {
        canvas.style.transform = 'scale(1)';
    }, 100);
}

// Start game
function startGame() {
    const playerName = document.getElementById('playerNameInput').value.trim();
    gameData.playerName = playerName || 'Player';
    
    // Reset game state
    resetGameState();
    
    // Start the game
    showScreen('gameScreen');
    gameState.isPlaying = true;
    
    // Start game loop
    startGameLoop();
}

// Reset game state
function resetGameState() {
    gameState.score = 0;
    gameState.obstacles = [];
    gameState.obstacleSpeed = CONFIG.OBSTACLE_SPEED_MIN;
    gameState.spawnRate = CONFIG.OBSTACLE_SPAWN_RATE;
    gameState.playerColorIndex = Math.floor(Math.random() * CONFIG.COLORS.length);
    gameState.player.colorIndex = gameState.playerColorIndex;
    gameState.player.x = CONFIG.CANVAS_WIDTH / 2;
    
    updateScoreDisplay();
    updateColorIndicator();
}

// Show specific screen
function showScreen(screenName) {
    const screens = ['startScreen', 'gameScreen', 'gameOverScreen'];
    screens.forEach(screen => {
        document.getElementById(screen).classList.remove('active');
    });
    
    if (screenName && document.getElementById(screenName)) {
        document.getElementById(screenName).classList.add('active');
    }
}

// Game loop
function startGameLoop() {
    if (animationId) cancelAnimationFrame(animationId);
    gameLoop();
}

function gameLoop() {
    if (!gameState.isPlaying) return;
    
    // Clear canvas
    ctx.clearRect(0, 0, CONFIG.CANVAS_WIDTH, CONFIG.CANVAS_HEIGHT);
    
    // Update game objects
    updateObstacles();
    checkCollisions();
    
    // Draw everything
    drawPlayer();
    drawObstacles();
    
    // Update difficulty
    updateDifficulty();
    
    // Continue loop
    animationId = requestAnimationFrame(gameLoop);
}

// Update obstacles
function updateObstacles() {
    if (Math.random() < gameState.spawnRate) {
        spawnObstacle();
    }
    
    // Move obstacles down
    gameState.obstacles.forEach(obstacle => {
        obstacle.y += obstacle.speed;
    });
    
    // Remove off-screen obstacles and increase score
    gameState.obstacles = gameState.obstacles.filter(obstacle => {
        if (obstacle.y > CONFIG.CANVAS_HEIGHT) {
            gameState.score++;
            updateScoreDisplay();
            return false;
        }
        return true;
    });
}

// Spawn obstacle
function spawnObstacle() {
    const x = Math.random() * (CONFIG.CANVAS_WIDTH - 80) + 40;
    const colorIndex = Math.floor(Math.random() * CONFIG.COLORS.length);
    const speed = gameState.obstacleSpeed + Math.random() * 2;
    
    gameState.obstacles.push({
        x: x,
        y: -50,
        width: 80,
        height: 20,
        colorIndex: colorIndex,
        speed: speed
    });
}

// Check collisions
function checkCollisions() {
    const player = gameState.player;
    
    for (let obstacle of gameState.obstacles) {
        // Simple collision detection
        if (obstacle.x < player.x + player.radius &&
            obstacle.x + obstacle.width > player.x - player.radius &&
            obstacle.y < player.y + player.radius &&
            obstacle.y + obstacle.height > player.y - player.radius) {
            
            // Check if colors match
            if (obstacle.colorIndex !== player.colorIndex) {
                gameOver();
                return;
            } else {
                // Successful pass - remove obstacle and add bonus score
                gameState.obstacles = gameState.obstacles.filter(obs => obs !== obstacle);
                gameState.score += 2; // Bonus for color matching
                updateScoreDisplay();
            }
        }
    }
}

// Draw player
function drawPlayer() {
    const { x, y, radius, colorIndex } = gameState.player;
    const color = CONFIG.COLORS[colorIndex];
    
    // Draw player circle
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fillStyle = color.value;
    ctx.fill();
    ctx.strokeStyle = '#333';
    ctx.lineWidth = 3;
    ctx.stroke();
    
    // Draw player inner detail
    ctx.beginPath();
    ctx.arc(x, y - 5, radius * 0.6, 0.3, Math.PI - 0.3);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
    ctx.fill();
}

// Draw obstacles
function drawObstacles() {
    gameState.obstacles.forEach(obstacle => {
        const color = CONFIG.COLORS[obstacle.colorIndex];
        
        // Draw obstacle rectangle
        ctx.fillStyle = color.value;
        ctx.fillRect(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
        
        // Add rounded corners effect
        ctx.fillStyle = color.value;
        ctx.beginPath();
        ctx.moveTo(obstacle.x + 5, obstacle.y);
        ctx.arcTo(obstacle.x + obstacle.width, obstacle.y, obstacle.x + obstacle.width, obstacle.y + 5, 5);
        ctx.arcTo(obstacle.x + obstacle.width, obstacle.y + obstacle.height, obstacle.x, obstacle.y + obstacle.height, 5);
        ctx.arcTo(obstacle.x, obstacle.y + obstacle.height, obstacle.x, obstacle.y, 5);
        ctx.arcTo(obstacle.x, obstacle.y, obstacle.x + obstacle.width, obstacle.y, 5);
        ctx.closePath();
        ctx.fill();
        
        // Add border
        ctx.strokeStyle = '#333';
        ctx.lineWidth = 2;
        ctx.strokeRect(obstacle.x, obstacle.y, obstacle.width, obstacle.height);
    });
}

// Update difficulty
function updateDifficulty() {
    // Increase speed and spawn rate based on score
    const difficultyLevel = Math.floor(gameState.score / 10);
    gameState.obstacleSpeed = Math.min(
        CONFIG.OBSTACLE_SPEED_MIN + (difficultyLevel * 0.5),
        CONFIG.OBSTACLE_SPEED_MAX
    );
    gameState.spawnRate = Math.min(
        CONFIG.OBSTACLE_SPAWN_RATE + (difficultyLevel * 0.01),
        0.08
    );
}

// Game over
function gameOver() {
    gameState.isPlaying = false;
    if (animationId) {
        cancelAnimationFrame(animationId);
        animationId = null;
    }
    
    // Update high score
    if (gameState.score > gameData.highScore) {
        gameData.highScore = gameState.score;
        document.getElementById('newHighScore').style.display = 'block';
    } else {
        document.getElementById('newHighScore').style.display = 'none';
    }
    
    // Save score
    if (gameData.playerName && gameState.score > 0) {
        saveGameData();
    }
    
    // Show game over screen
    document.getElementById('finalScore').textContent = `Score: ${gameState.score}`;
    document.getElementById('finalHighScore').textContent = gameData.highScore;
    
    setTimeout(() => {
        showScreen('gameOverScreen');
    }, 500);
}

// Restart game
function restartGame() {
    showScreen('gameScreen');
    resetGameState();
    gameState.isPlaying = true;
    startGameLoop();
}

// Close game
function closeGame() {
    try {
        window.parent.postMessage({
            type: 'applaa-game-save-score',
            gameId: 'color-switch-runner',
            playerName: gameData.playerName,
            score: gameState.score
        }, '*');
    } catch (e) {
        // Silently fail if parent is not available
    }
    window.close();
}

// Update score display
function updateScoreDisplay() {
    document.getElementById('scoreDisplay').textContent = `Score: ${gameState.score}`;
}

// Update high score display
function updateHighScoreDisplay() {
    document.getElementById('highScoreDisplay').textContent = `High Score: ${gameData.highScore}`;
    document.getElementById('highScoreDisplay').style.display = 'block';
}

// Update color indicator
function updateColorIndicator() {
    const currentColor = CONFIG.COLORS[gameState.playerColorIndex];
    document.getElementById('currentColor').textContent = currentColor.emoji;
}

// Display leaderboard (from parent data)
function displayLeaderboard(scores) {
    if (!scores || scores.length === 0) return;
    
    const container = document.getElementById('leaderboardContainer');
    container.style.display = 'block';
    
    const topScores = scores
        .filter(s => s.playerName && s.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, 5);
    
    const listElement = document.getElementById('topScoresList');
    listElement.innerHTML = '';
    
    topScores.forEach((score, index) => {
        const div = document.createElement('div');
        div.textContent = `${index + 1}. ${score.playerName} - ${score.score}`;
        listElement.appendChild(div);
    });
}

// Initialize the game when page loads
window.addEventListener('load', init);