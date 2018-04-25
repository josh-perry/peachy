local aseprite = require("aseprite")

local count
local colours

function love.load()
	count = aseprite.new("examples/countAndColours.json")
	count:setTag("Numbers")
	count:play()

	colours = aseprite.new("examples/countAndColours.json")
	colours:setTag("Colours")
	colours:play()
end

function love.draw()
	love.graphics.print("countAndColours.json", 15, 15)
	love.graphics.print("Numbers", 50, 50)
	count:draw(50, 80)

	love.graphics.print("Colours", 150, 50)
	colours:draw(150, 80)
end

function love.update(dt)
	count:update(dt)
	colours:update(dt)
end