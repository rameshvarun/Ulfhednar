RELEASE = false

class = require "libraries.middleclass" -- Object oriented programming
stateful = require "libraries.stateful" -- Stateful objects
vector = require "libraries.vector" -- Vector utilities
_ = require 'libraries.underscore' -- Underscore.lua
lume = require "libraries.lume" -- Game utilities
SLAXML = require "libraries.slaxdom" -- XML Parser
serpent = require "libraries.serpent" -- Table serialization

if not RELEASE then
	lurker = require "libraries.lurker" -- Live code reload
end

require 'util'
require 'collision'

--Import all menu scripts
load_scripts("menu")
print("Loaded all menu scripts")

require 'gamestate'

--Import all enemy code
enemytypes = {}
load_scripts("enemies", true)
print("Loaded all enemy scripts.")

--Import all props
proptypes = {}
load_scripts("props", true)
print("Loaded all prop scripts.")

--Load in all bullets
load_scripts("bullets", true)
print("Loaded all bullet scripts.")

-- Load in all entities
load_scripts("entities", true)

--Stores whether or not the game has the current focus
focus = true

function love.load(arg)
	--Make cursor invisible
	love.mouse.setVisible( false )

	--Default settings for the physics engine
	love.physics.setMeter(64)

	--Start astar thread (Essentially processes pathfinding jobs, and returns viable paths to units that request it)
	astarthread = love.thread.newThread('astar.lua')
	astarthread:start()

	-- Create remote server thread (don't start it though)
	remoteserver = love.thread.newThread('remoteserver.lua')
	remoteserver:start()
	remotechannel = love.thread.getChannel('remotes')

	--Load globally used sound assets
	explosion1 = love.sound.newSoundData("sound/explosion1.wav")
	pickup1 = love.sound.newSoundData("sound/pickup1.wav")

	door_sfx = love.audio.newSource("sound/door.wav", "static")
	spike_sfx = love.audio.newSource("sound/spike.wav", "static")
	splat_sfx = love.audio.newSource("sound/splat.wav", "static")

	hurt1_sfx = love.audio.newSource("sound/hurt1.wav", "static")
	hurt1_sfx:setVolume(0.2)

	--Post-processing setup
	bloom_shader = love.graphics.newShader( "effects/bloom.frag" )
	render_canvas = love.graphics.newCanvas()

	--Load globally used fonts
	caesardressing100 = love.graphics.newFont("fonts/CaesarDressing-Regular.ttf", 100)
	caesardressing80 = love.graphics.newFont("fonts/CaesarDressing-Regular.ttf", 80)
	caesardressing40 = love.graphics.newFont("fonts/CaesarDressing-Regular.ttf", 40)
	caesardressing30 = love.graphics.newFont("fonts/CaesarDressing-Regular.ttf", 30)
	caesardressing20 = love.graphics.newFont("fonts/CaesarDressing-Regular.ttf", 20)

	love.graphics.setBackgroundColor( 255, 255, 255 ) --Set background color to white

	math.randomseed( os.time() ) --Seed random generator with current time

	--Music stuff
	current_music_file = nil
	music_source = nil

	--These two lines are just for testing. Eventually, it should launch menu first, which then redirects to the game state
	--local players = { KeyboardPlayer:new(), GamepadPlayer(love.joystick.getJoysticks()[1]), GamepadPlayer(love.joystick.getJoysticks()[2])}
	local players = { KeyboardPlayer:new("z", "x", "up", "left", "down", "right") }
	--currentstate = GameState:new(players, "hellfloor1.tmx")
	--currentstate = MapMenu:new(players)

	currentstate = ControlMenu:new()
	--currentstate = Credits:new()
end

--Global logic for switching between background music files
function setMusic( music_file, music_volume )
	--Default Music volume
	if music_volume == nil then
		music_volume = 0.1
	end

	if not(current_music_file == music_file) then
		if not(music_source == nil) then
			music_source:stop()
		end

		music_source = love.audio.newSource( "sound/music/" .. music_file , "stream" )
		music_source:setLooping(true)
		music_source:play()
		music_source:setVolume( music_volume )

		current_music_file = music_file
	end
end

REMOTES = {}
function love.update(dt)
	if not RELEASE then
		lurker.update() -- Live reload system
	end

	-- Get remote updates from remote channel
	if remoteserver:isRunning() then
		while remotechannel:getCount() > 0 do
			REMOTES = lume.deserialize(remotechannel:pop())
		end
	end

  	--If an error has occurred in the a-star thread, report it
	if not(astarthread==nil) and astarthread:isRunning() == false then
		print( "Error in A-star Thread!")
		print( astarthread:getError() )

		--Restart thread
		astarthread = love.thread.newThread('astar.lua')
		astarthread:start()
	end

	--Only update the game if the window has focus
	if focus == true then
		currentstate:update(dt)
	end
end

--Forward mouspresses to gamestate
function love.mousepressed(x, y, button)
	currentstate:mousepressed(x, y, button)
end


function love.mousereleased(x, y, button)
	currentstate:mousereleased(x, y, button)
end

--Flip focus variable on focus events
function love.focus(f) focus = f end

function love.keypressed(key, unicode)
	currentstate:keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	--'f' key toggles fullscreen and windowed mode
	if key == "f" then
		local width, height, flags = love.window.getMode( )

		if not flags.fullscreen then
			flags.fullscreen = true
			local modes = love.window.getFullscreenModes( ) --Get all modes
			table.sort(modes, function(a, b) return a.width*a.height < b.width*b.height end) -- sort from smallest to largest
			love.window.setMode( modes[ #modes ].width, modes[ #modes ].height, flags )
		else
			flags.fullscreen = false
			love.window.setMode( 1280, 720, flags )
		end

		--Create new canvas for post-processing
		render_canvas = love.graphics.newCanvas()
	else
		currentstate:keyreleased(key, unicode)
	end
end

function love.draw()
	--Render gamestate to the canvas
	love.graphics.setShader()
	love.graphics.setCanvas(render_canvas)
	love.graphics.clear()
	currentstate:draw()

	--Render canvas to screen with bloom_shader
	love.graphics.setColor( 255, 255, 255, 255 )
	love.graphics.setShader(bloom_shader)
	love.graphics.setCanvas()
	love.graphics.draw(render_canvas, 0, 0)

	--Draw game UI
	love.graphics.setShader()
	love.graphics.setCanvas()
	if currentstate.ui ~= nil then
		currentstate:ui()
	end
end
