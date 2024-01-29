extends Node2D

var rng = RandomNumberGenerator.new()

#state
enum GAME_STATE {MENU, SERVE, PLAY, END}
var isPlayerServe = true

var currentGameState = GAME_STATE.MENU

# screen values
onready var screenWidth = get_tree().get_root().size.x
onready var screenHeight = get_tree().get_root().size.y
onready var halfScreenWidth = screenWidth / 2
onready var halfScreenHeight = screenHeight / 2

# paddle values
var paddleColor = Color.white
var paddleSize = Vector2(10, 100)
var halfPaddleHeight = paddleSize.y / 2
var paddlePadding = 10.0
# player paddle
onready var playerStartingPosition = Vector2(paddlePadding, halfScreenHeight - halfPaddleHeight)
onready var playerPosition = playerStartingPosition
onready var playerRectangle = Rect2(playerPosition, paddleSize)

#ai paddle
onready var aiStartingPosition = Vector2(screenWidth - (paddlePadding + paddleSize.x), 
halfScreenHeight - halfPaddleHeight)
onready var aiPosition = aiStartingPosition
onready var aiRectangle = Rect2(aiPosition, paddleSize)

# ballValues
var ballRadius = 10.0
var ballColor = Color.white
var ballSize = Vector2(ballRadius*2, ballRadius*2)
onready var startingBallPosition = Vector2(halfScreenWidth, halfScreenHeight)
onready var ballPosition = startingBallPosition
onready var ballRectangle = Rect2(getBallPosition(ballPosition), ballSize)

# fonts
var font = DynamicFont.new()
var robotoFontFile = load("Roboto-Light.ttf")
var fontSize = 24
var halfWidthFont
var heightFont
var stringValue = "Pong game!"
var stringPosition

const RESET_MENU_INPUT_DELAT = 0.0
const MENU_INPUT_DELAY = 0.3
var menuInputDelta = RESET_MENU_INPUT_DELAT

var ballStartingSpeed = Vector2(400.0, 0.0)
var ballSpeed = ballStartingSpeed

var playerSpeed = 200.0
var aiSpeed = 250.0
var aiHitPoint

var playerScore = 0
var playerScorePosition
var aiScore = 0
var aiScorePosition

var menuText = [
	"PONG",
	"",
	"Controlls:",
	"W,S - control your paddle position",
	"SPACE - serve / start game",
	"",
	"Press SPACE to continue..."
]

const wonText = "You won!"
const lostText = "You lost!"
const endContinueText = "press SPACE to continue...";

func getBallPosition(ballPosition: Vector2) -> Vector2:
	return Vector2(ballPosition.x - ballRadius, ballPosition.y - ballRadius)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	setupAiHitPoint()
	font.font_data = robotoFontFile
	font.size = fontSize
	heightFont = font.get_height()
	updateText()
	updateScore(0, true)
	updateScore(0, false)
	
func setupAiHitPoint():
	aiHitPoint = rng.randf_range(-40.0, 40.0)

func updateText(text: String = ""):
	if (text != ""):
		stringValue = text
	halfWidthFont = font.get_string_size(stringValue).x / 2
	stringPosition = Vector2(halfScreenWidth - halfWidthFont, heightFont)

func updateScore(value: int, isAi: bool):
	var stringValue = str(value)
	var stringHalfWidth = font.get_string_size(stringValue).x / 2
	if isAi:
		aiScorePosition = Vector2(halfScreenWidth + (halfScreenWidth / 2) - halfWidthFont, heightFont)
	else:
		playerScorePosition = Vector2((halfScreenWidth / 2) - halfWidthFont, heightFont)

func isSpacePressed():
	if (Input.is_key_pressed(KEY_SPACE) and menuInputDelta > MENU_INPUT_DELAY):
		menuInputDelta = RESET_MENU_INPUT_DELAT
		return true
	return false

func _physics_process(delta):
	menuInputDelta += delta
	
	match currentGameState:
		GAME_STATE.MENU:
			actionMenu(delta)
		GAME_STATE.SERVE:
			actionServe(delta)
		GAME_STATE.PLAY:
			actionPlay(delta)
		GAME_STATE.END:
			actionEnd(delta)

func actionEnd(delta):
	if isSpacePressed():
		aiScore = 0
		playerScore = 0
		currentGameState = GAME_STATE.SERVE
	pass

func actionMenu(delta):
	updateText('Menu')
	if isSpacePressed():
		currentGameState = GAME_STATE.SERVE
	update()

func actionServe(delta):
	ballPosition = startingBallPosition
	updateText('Serve')
	if isPlayerServe:
		ballSpeed = ballStartingSpeed
		updateText("Player serve")
	else:
		updateText("AI serve")
		ballSpeed = -ballStartingSpeed
	if isSpacePressed():
		currentGameState = GAME_STATE.PLAY

	ballPosition += ballSpeed * delta
	ballRectangle = Rect2(getBallPosition(ballPosition), ballSize)
	
	playerRectangle.position = playerStartingPosition
	playerPosition = playerStartingPosition
	aiRectangle.position = aiStartingPosition
	aiPosition = aiStartingPosition
	update()

func actionPlay(delta):
	updateText('Playing...')
	
	if ballPosition.x <= 0:
		currentGameState = GAME_STATE.SERVE
		menuInputDelta = RESET_MENU_INPUT_DELAT
		aiScore += 1
		updateScore(aiScore, false)
		isPlayerServe = true
	if ballPosition.x >= screenWidth:
		currentGameState = GAME_STATE.SERVE
		playerScore += 1
		updateScore(playerScore, false)
		menuInputDelta = RESET_MENU_INPUT_DELAT
		isPlayerServe = false
		
	if (aiScore >= 3 or playerScore >= 3) and playerScore != aiScore:
		currentGameState = GAME_STATE.END
		
	if ballPosition.y <= 0 or ballPosition.y >= screenHeight:
		ballSpeed = Vector2(ballSpeed.x, -ballSpeed.y)
		
	if isBallColliding(playerRectangle):
		var ballDelta = getBallToPaddleDelta(playerRectangle)
		ballSpeed = Vector2(-ballSpeed.x, 400 * ballDelta)
	if isBallColliding(aiRectangle):
		var ballDelta = getBallToPaddleDelta(aiRectangle)
		ballSpeed = Vector2(-ballSpeed.x, 400 * ballDelta)
		setupAiHitPoint()

	ballPosition += ballSpeed * delta
	ballRectangle = Rect2(getBallPosition(ballPosition), ballSize)
		
	if Input.is_key_pressed(KEY_W):
		playerPosition.y += -playerSpeed * delta
		playerPosition.y = clamp(playerPosition.y, 0, screenHeight - paddleSize.y )
		playerRectangle = Rect2(playerPosition, paddleSize)
	if Input.is_key_pressed(KEY_S):
		playerPosition.y += playerSpeed * delta
		playerPosition.y = clamp(playerPosition.y, 0, screenHeight - paddleSize.y )
		playerRectangle = Rect2(playerPosition, paddleSize)
	
	if (ballPosition.y > aiPosition.y + (paddleSize.y / 2 + aiHitPoint)):
		aiPosition.y += aiSpeed * delta
	if (ballPosition.y < aiPosition.y + (paddleSize.y / 2 + aiHitPoint)):
		aiPosition.y -= aiSpeed * delta
	aiPosition.y = clamp(aiPosition.y, 0, screenHeight - paddleSize.y )
	aiRectangle.position.y = aiPosition.y
	update()

func isBallColliding(paddlePos: Rect2) -> bool:
	var ballRect = Rect2(Vector2(ballPosition.x - ballRadius, ballPosition.y - ballRadius),
	Vector2(ballRadius*2, ballRadius* 2))
	
	return ballRect.intersects(paddlePos)

func getBallToPaddleDelta(paddlePos: Rect2) -> float:
	if !isBallColliding(paddlePos):
		return 0.0
	var paddleStart = paddlePos.position.y
	var paddleSize = paddlePos.size.y
	var middle = paddleSize / 2
	var ballPos = ballPosition.y - paddleStart
	
	if ballPos > middle:
		return float((ballPos - middle)) / float(middle)
	if (ballPos < middle):
		return float(ballPos) / float(middle) - 1.0
	return 0.0

func _draw():
	if currentGameState == GAME_STATE.MENU:
		var lineHeight = 50
		for text in menuText:
			draw_string(font, Vector2(50, lineHeight), text)
			lineHeight += fontSize + 5
	if currentGameState == GAME_STATE.END:
		if playerScore > aiScore:
			draw_string(font, Vector2(halfScreenWidth - font.get_string_size(wonText).x / 2, 100), wonText)
		else:
			draw_string(font, Vector2(halfScreenWidth - font.get_string_size(lostText).x / 2 , 100), lostText)

		var scoreText = str(playerScore)+ " - "+str(aiScore)
		draw_string(font, Vector2(halfScreenWidth - font.get_string_size(scoreText).x / 2, 140), scoreText)
		draw_string(font, Vector2(halfScreenWidth - font.get_string_size(endContinueText).x / 2, screenHeight - 100), endContinueText)
			
	if currentGameState == GAME_STATE.PLAY or currentGameState == GAME_STATE.SERVE:
		setStartingPosition()
		draw_string(font, playerScorePosition, str(playerScore))
		draw_string(font, aiScorePosition, str(aiScore))

func setStartingPosition():
	draw_rect(ballRectangle, ballColor)
	draw_rect(playerRectangle, paddleColor)
	draw_rect(aiRectangle, paddleColor)
	draw_string(font, stringPosition, stringValue)
