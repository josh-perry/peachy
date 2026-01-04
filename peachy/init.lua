--- A parser/renderer for Aseprite animations in LÖVE.
---@class peachy
---@field image love.Image
---@field frames table[]
---@field frameTags table<string, table>
---@field paused boolean
---@field tag table?
---@field tagName string?
---@field direction string?
---@field frameIndex integer?
---@field frame table?
---@field frameTimeAccumulator number
---@field jsonPath string|table
---@field private __jsonData table
---@field private __callbackOnLoop function?
---@field private __argsOnLoop table?
local peachy = {
	__VERSION = "1.0.0-alpha",
	__DESCRIPTION = "A parser/renderer for Aseprite animations in LÖVE.",
	__URL = "https://github.com/josh-perry/peachy",
	__LICENSE = [[
		MIT License

		Copyright (c) 2018 Josh Perry

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	]]
}

local PATH = ...
local json = require(PATH .. ".lib.json")

peachy.__index = peachy

--- Creates a new Peachy animation object.
---
--- If imageData isn't specified then Peachy will attempt to load it using the
--- filename from the JSON data.
---
--- If no initial tag is set then the object will be paused (i.e. not displayed) with no tag.
--- The animation will start playing immediately once created.
---
--- Example:
--- ```lua
--- -- Load the image ourselves and set animation tag to "Spin".
--- -- Will start playing immediately.
--- spinner = peachy.new("spinner.json", love.graphics.newImage("spinner.png"), "Spin")
--- ```
---@param data string|table Path to an Aseprite JSON file or a predecoded table
---@param image love.Image? A LÖVE image
---@param initialTag string? The name of the animation tag to use initially
---@return peachy
function peachy.new(data, image, initialTag)
	assert(data ~= nil, "No JSON data!")

	local self = setmetatable({}, peachy)

	-- Check if datafile is a lua table (i.e. pre decoded)
	if type(data) == 'table' then
		self.__jsonData = data
	else
		-- Read the data
		self.__jsonData = json.decode(love.filesystem.read(data))
		self.jsonPath = data
	end

	-- Load the image
	self.image = image or love.graphics.newImage(self.__jsonData.meta.image)

	self:__initializeFrames()
	self:__initializeTags()

	self.paused = true

	self.tag = nil
	self.tagName = nil
	self.direction = nil
	self.frameTimeAccumulator = 0

	if initialTag then
		self:setTag(initialTag)
		self.paused = false
	end

	return self
end

--- Switch to a different animation tag.
--- In the case that we're attempting to switch to the animation currently playing,
--- nothing will happen.
---@param tag string The tag name to switch to
function peachy:setTag(tag)
	assert(tag, "No animation tag specified!")
	assert(self.frameTags[tag], "Tag " .. tag .. " not found in frametags!")

	if self.tag == self.frameTags[tag] then
		return
	end

	self.tagName = tag
	self.tag = self.frameTags[self.tagName]
	self.frameIndex = nil
	self.direction = self.tag.direction

	if self.direction == "pingpong" then
		self.direction = "forward"
	end

	self:nextFrame()
end

--- Jump to a particular frame index (1-based indexes) in the current animation.
---
--- Errors if the frame is outside the tag's frame range.
---
--- Example:
--- ```lua
--- -- Go to the 4th frame
--- sound:setFrame(4)
--- ```
---@param frame integer The frame index to jump to
function peachy:setFrame(frame)
	if frame < 1 or frame > #self.tag.frames then
		error(("Frame %d is out of range of tag '%s' (1..%d)"):format(frame, self.tagName, #self.tag.frames))
	end

	self.frameIndex = frame

	self.frame = self.tag.frames[self.frameIndex]
	self.frameTimeAccumulator = 0
end

--- Get the current frame of the current animation
---@return integer?
function peachy:getFrame()
	return self.frameIndex
end

--- Get the current tag's name
---@return string?
function peachy:getTag()
	return self.tagName
end

--- Get the json path passed in the object
---@return string|table
function peachy:getJSON()
	return self.jsonPath
end

--- Draw the animation's current frame in a specified location.
---@param x number The x position
---@param y number The y position
---@param rot number? The rotation to draw at
---@param sx number? The x scaling
---@param sy number? The y scaling
---@param ox number? The origin offset x
---@param oy number? The origin offset y
function peachy:draw(x, y, rot, sx, sy, ox, oy)
	if not self.frame then
		return
	end

	love.graphics.draw(self.image, self.frame.quad, x, y, rot or 0, sx or 1, sy or 1, ox or 0, oy or 0)
end

--- Update the animation.
---@param dt number Frame delta in seconds. Should be called from love.update
function peachy:update(dt)
	if self.paused then
		return
	end

	assert(dt, "No dt passed into update!")
	assert(self.tag, "No animation tag has been set!")
	assert(self.frameTimeAccumulator, "Frame time accumulator hasn't been initialized!")

	self.frameTimeAccumulator = self.frameTimeAccumulator + (dt * 1000)

	-- Handle frame advancement, skipping frames if dt spike occurred
	while self.frameTimeAccumulator >= self.frame.duration do
		self.frameTimeAccumulator = self.frameTimeAccumulator - self.frame.duration
		self:nextFrame()
	end
end

--- Move to the next frame.
--- Unless you want to skip frames, this generally will not ever
--- need to be called manually.
function peachy:nextFrame()
	local forward = self.direction == "forward"

	if forward then
		self.frameIndex = (self.frameIndex or 0) + 1
	else
		self.frameIndex = (self.frameIndex or #self.tag.frames + 1) - 1
	end

	-- Looping
	if forward and self.frameIndex > #self.tag.frames then
		if self.tag.direction == "pingpong" then
			self:__pingpongBounce()
		else
			self.frameIndex = 1
		end

		self:__callOnLoop()
	elseif not forward and self.frameIndex < 1 then
		if self.tag.direction == "pingpong" then
			self:__pingpongBounce()
		else
			self.frameIndex = #self.tag.frames
			self:__callOnLoop()
		end
	end

	self.frame = self.tag.frames[self.frameIndex]
end

--- Check for callbacks
---@package
function peachy:__callOnLoop()
	if self.__callbackOnLoop then self.__callbackOnLoop(unpack(self.__argsOnLoop)) end
end

--- Pauses the animation.
function peachy:pause()
	self.paused = true
end

--- Unpauses the animation.
function peachy:play()
	self.paused = false
end

--- Stops the animation (pause it then return to first frame or last if specified)
---@param onLast boolean? If true, stop on last frame instead of first
function peachy:stop(onLast)
	local index = 1
	self.paused = true
	if onLast then index = #self.tag.frames end
	self:setFrame(index)
end

--- Adds a callback function that will be called when the animation loops
---@param fn function The callback function to call on loop
---@param ... any Additional arguments to pass to the callback
function peachy:onLoop(fn, ...)
	self.__callbackOnLoop = fn
	self.__argsOnLoop = { ... }
end

--- Toggle between playing/paused.
function peachy:togglePlay()
	if self.paused then
		self:play()
	else
		self:pause()
	end
end

--- Provides width stored in the metadata of a current frame
---@return number
function peachy:getWidth()
	return self.__jsonData.frames[self.frameIndex].frame.w
end

--- Provides height stored in the metadata of a current frame
---@return number
function peachy:getHeight()
	return self.__jsonData.frames[self.frameIndex].frame.h
end

--- Provides dimensions stored in the metadata of a current frame
---@return number width
---@return number height
function peachy:getDimensions()
	return self:getWidth(), self:getHeight()
end

--- Handles the ping-pong animation type.
--- Should only be called when we actually want to bounce.
--- Swaps the direction.
---@private
function peachy:__pingpongBounce()
	-- We need to increment/decrement frame index by 2 because
	-- at this point we've already gone to the next frame
	if self.direction == "forward" then
		self.direction = "reverse"
		self.frameIndex = self.frameIndex - 2
	else
		self.direction = "forward"
		self.frameIndex = self.frameIndex + 2
	end
end

--- Loads quads and frame duration data from the JSON.
---@private
function peachy:__initializeFrames()
	assert(self.__jsonData ~= nil, "No JSON data!")
	assert(self.__jsonData.meta ~= nil, "No metadata in JSON!")
	assert(self.__jsonData.frames ~= nil, "No frame data in JSON!")

	-- Initialize all the quads
	self.frames = {}
	for _, frameData in ipairs(self.__jsonData.frames) do
		local frame = {}

		local fd = frameData.frame
		frame.quad = love.graphics.newQuad(fd.x, fd.y, fd.w, fd.h, self.image)
		frame.duration = frameData.duration

		table.insert(self.frames, frame)
	end
end

--- Loads all of the animation tags
---@private
function peachy:__initializeTags()
	assert(self.__jsonData ~= nil, "No JSON data!")
	assert(self.__jsonData.meta ~= nil, "No metadata in JSON!")
	assert(self.__jsonData.meta.frameTags ~= nil, "No frame tags in JSON! Make sure you exported them in Aseprite!")

	self.frameTags = {}

	for _, frameTag in ipairs(self.__jsonData.meta.frameTags) do
		local ft = {}
		ft.direction = frameTag.direction
		ft.frames = {}

		for frame = frameTag.from + 1, frameTag.to + 1 do
			table.insert(ft.frames, self.frames[frame])
		end

		self.frameTags[frameTag.name] = ft
	end
end

return peachy
