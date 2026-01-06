local peachy = require("peachy")

local man = require("examples.man")

love.window.setTitle("Peachy example - 🍑")

local spriteSheet = love.graphics.newImage("examples/countAndColours.png")

local count = peachy.new("examples/countAndColours.json", spriteSheet, "Numbers")
local colours = peachy.new("examples/countAndColours.json", spriteSheet, "Colours")
local countReverse = peachy.new("examples/countAndColours.json", spriteSheet, "NumbersDown")
local countPingPong = peachy.new("examples/countAndColours.json", spriteSheet, "PingPong")
local spinner = peachy.new("examples/spinner.json", love.graphics.newImage("examples/spinner.png"), "Spin")
local sound = peachy.new("examples/sound.json", love.graphics.newImage("examples/sound.png"), "Bounce")
local faces = peachy.new("examples/faces.json", love.graphics.newImage("examples/faces.png"))

local currentFace = nil

local blip = love.audio.newSource("examples/blip.wav", "static")
blip:setVolume(0.3)

countPingPong:onLoop(function() print("Hey I'm in pingpong mode!") end)
countReverse:onLoop(function() print("Hey I'm in reverse mode!") end)
spinner:onLoop(function(a, b, c)
	print("I'm spinning!")
	print(("My arguments:%i %i %i"):format(a, b, c))
end, 1, 2, 3)

function love.draw()
	love.graphics.setColor(1, 1, 1)

	love.graphics.print("countAndColours.json", 15, 15)
	love.graphics.print("Tag", 50, 50)
	count:draw(50, 80)

	love.graphics.print("Different tag", 150, 50)
	colours:draw(150, 80)

	love.graphics.print("Reverse", 250, 50)
	countReverse:draw(250, 80)

	love.graphics.print("Ping-Pong", 350, 50)
	countPingPong:draw(350, 80)

	love.graphics.print("man.json", 15, 215)
	love.graphics.print("Walk around with arrow keys", 50, 250)
	love.graphics.print(man.sprite.tagName, man.x, man.y + 30)
	love.graphics.print((man.sprite.paused and "Paused" or "Playing"), man.x, man.y + 45)
	love.graphics.print("Frame " .. man.sprite.frameIndex, man.x, man.y + 60)
	man.sprite:draw(man.x, man.y)

	love.graphics.print("spinner.json", 15, 415)
	love.graphics.print("Press space to pause/play", 50, 450)
	spinner:draw(50, 480)

	love.graphics.print("sound.json", 415, 215)
	love.graphics.print("Press space to pause/play", 450, 250)
	sound:draw(450, 280)

	love.graphics.print("faces.json (slices)", 415, 415)
	love.graphics.print("Press F for face", 450, 450)

	if currentFace then
		faces:drawSlice(currentFace, 450, 480)
		love.graphics.print(currentFace, 450, 520)

		local slice = faces:getSlice(currentFace)

		if slice then
			if slice.color then
				love.graphics.setColor(slice.color)
				love.graphics.rectangle("line", 450, 480, slice.bounds.w, slice.bounds.h)
			end

			if slice.data then
				love.graphics.setColor(1, 1, 1)
				love.graphics.print(("Slice data: %s"):format(slice.data), 450, 540)
			end
		end
	end
end

function love.update(dt)
	count:update(dt)
	colours:update(dt)
	countReverse:update(dt)
	countPingPong:update(dt)
	spinner:update(dt)
	sound:update(dt)

	man:movement(dt)
	man.sprite:update(dt)

	if not sound.paused and sound.frameIndex == 1 or sound.frameIndex == 16 then
		blip:play()
	end
end

function love.keypressed(key)
	if key == "space" then
		spinner:togglePlay()
		sound:togglePlay()
	elseif key == "f" then
		local sliceNames = faces:getSliceNames()
		if #sliceNames > 0 then
			currentFace = sliceNames[love.math.random(1, #sliceNames)]
		end
	end
end
