local aseprite = require("aseprite")
local animations = {}

function love.load()
	for i = 0, 5 do
		table.insert(animations, aseprite.new("examples/count.json"))
	end

	animations[2]:pause()
end

function love.draw()
	for i, anim in ipairs(animations) do
		anim:draw(i * 50, 0)
	end
end

function love.update(dt)
	for _, anim in ipairs(animations) do
		anim:update(dt)
	end
end