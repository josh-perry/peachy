local aseprite = require("aseprite")

local count
local colours
local countReverse
local countPingPong

function love.load()
	count = aseprite.new("examples/countAndColours.json")
	count:setTag("Numbers")
	count:play()

	colours = aseprite.new("examples/countAndColours.json")
	colours:setTag("Colours")
	colours:play()

	countReverse = aseprite.new("examples/countAndColours.json")
	countReverse:setTag("NumbersDown")
	countReverse:play()

	countPingPong = aseprite.new("examples/countAndColours.json")
	countPingPong:setTag("PingPong")
	countPingPong:play()
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