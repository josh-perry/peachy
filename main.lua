local aseprite = require("aseprite")

local count
local colours
local countReverse
local countPingPong
local spriteSheet

function love.load()
	spriteSheet = love.graphics.newImage("examples/countAndColours.png")

	count = aseprite.new("examples/countAndColours.json", spriteSheet, "Numbers")
	colours = aseprite.new("examples/countAndColours.json", spriteSheet, "Colours")
	countReverse = aseprite.new("examples/countAndColours.json", spriteSheet, "NumbersDown")
	countPingPong = aseprite.new("examples/countAndColours.json", spriteSheet, "PingPong")
end

function love.draw()
	love.graphics.print("countAndColours.json", 15, 15)
	love.graphics.print("Numbers", 50, 50)
	count:draw(50, 80)

	love.graphics.print("Colours", 150, 50)
	colours:draw(150, 80)

	love.graphics.print("Numbers reverse", 250, 50)
	countReverse:draw(250, 80)

	love.graphics.print("Numbers ping pong", 350, 50)
	countPingPong:draw(350, 80)
end

function love.update(dt)
	count:update(dt)
	colours:update(dt)
	countReverse:update(dt)
	countPingPong:update(dt)
end