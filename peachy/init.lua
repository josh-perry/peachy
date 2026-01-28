--- A slice object representing a named rectangle in the image.
---@class Slice
---@field bounds {x: number, y: number, w: number, h: number} The bounding rectangle of the slice
---@field quad love.Quad The quad used for rendering this slice
---@field color number[]? Normalized RGBA colour values (0-1) (the border colour - at least in Aseprite)
---@field data string? Custom user data

--- A parser/renderer for Aseprite animations in LÖVE.
---@class peachy
---@field image love.Image
---@field frames table[]
---@field frameTags table<string, table>
---@field slices table<string, Slice>
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
	self:__initializeSlices()

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

--- Get a slice by name
---@param name string The slice name
---@return Slice? The slice object or nil if not found
function peachy:getSlice(name)
	assert(name, "No slice name specified!")
	return self.slices[name]
end

--- Get all slice names
---@return string[] Array of slice names
function peachy:getSliceNames()
	local names = {}
	for name, _ in pairs(self.slices) do
		table.insert(names, name)
	end
	return names
end

--- Check if a slice exists
---@param name string The slice name
---@return boolean
function peachy:hasSlice(name)
	return self.slices[name] ~= nil
end

--- Draw a slice at the specified position
---@param name string The slice name
---@param x number The x position
---@param y number The y position
---@param rot number? The rotation to draw at
---@param sx number? The x scaling
---@param sy number? The y scaling
---@param ox number? The origin offset x
---@param oy number? The origin offset y
function peachy:drawSlice(name, x, y, rot, sx, sy, ox, oy)
	local slice = self:getSlice(name)
	assert(slice, ("Slice '%s' not found!"):format(name))

	love.graphics.draw(self.image, slice.quad, x, y, rot or 0, sx or 1, sy or 1, ox or 0, oy or 0)
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

--- Sorts frames from hash format by index
--- ---@param frames table[] The frames to sort
--- ---@private
function peachy:__sortHashFrames(frames)
	table.sort(frames, function(a, b) return a.index < b.index end)
end

--- Converts hash format frames to array format
---@private
function peachy:__convertHashFramesToArray()
	local framesArray = {}

	for filename, frameData in pairs(self.__jsonData.frames) do
		local frameIndex = tonumber(filename:match("(%d+)%.aseprite") or filename:match("(%d+)%.ase"))

		if frameIndex then
			frameData.filename = filename
			table.insert(framesArray, { index = frameIndex, data = frameData })
		end
	end

	self:__sortHashFrames(framesArray)

	local normalisedFrames = {}
	for _, entry in ipairs(framesArray) do
		table.insert(normalisedFrames, entry.data)
	end

	self.__jsonData.frames = normalisedFrames
end

--- Loads quads and frame duration data from the JSON.
---@private
function peachy:__initializeFrames()
	assert(self.__jsonData ~= nil, "No JSON data!")
	assert(self.__jsonData.meta ~= nil, "No metadata in JSON!")
	assert(self.__jsonData.frames ~= nil, "No frame data in JSON!")

	local isArrayStyleExport = self.__jsonData.frames[1] ~= nil

	-- If hash format, normalise to array
	if not isArrayStyleExport then
		self:__convertHashFramesToArray()
	end

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

--- Converts a hex colour string (e.g. "#0000ffff") to a normalised RGBA table
---@param hex string The hex colour string
---@return number[]? Normalized RGBA values (0-1) as array {r, g, b, a} or nil if invalid
---@private
function peachy:__hexToColor(hex)
	if not hex or type(hex) ~= "string" then
		return nil
	end

	hex = hex:gsub("#", "")

	if #hex == 8 then
		local rb = tonumber(hex:sub(1, 2), 16)
		local gb = tonumber(hex:sub(3, 4), 16)
		local bb = tonumber(hex:sub(5, 6), 16)
		local ab = tonumber(hex:sub(7, 8), 16)

		if rb and gb and bb and ab then
			local r, g, b, a = love.math.colorFromBytes(rb, gb, bb, ab)
			return { r, g, b, a }
		end
	elseif #hex == 6 then
		local rb = tonumber(hex:sub(1, 2), 16)
		local gb = tonumber(hex:sub(3, 4), 16)
		local bb = tonumber(hex:sub(5, 6), 16)

		if rb and gb and bb then
			local r, g, b, a = love.math.colorFromBytes(rb, gb, bb, 255)
			return { r, g, b, a }
		end
	end

	return nil
end

--- Loads all of the slices from the JSON
---@private
function peachy:__initializeSlices()
	assert(self.__jsonData ~= nil, "No JSON data!")
	assert(self.__jsonData.meta ~= nil, "No metadata in JSON!")

	if not self.__jsonData.meta.slices then
		self.slices = {}
		return
	end

	self.slices = {}

	for _, slice in ipairs(self.__jsonData.meta.slices) do
		assert(slice.keys and #slice.keys > 0, "Slice '" .. slice.name .. "' has no keys!")
		assert(slice.keys[1].bounds, "Slice '" .. slice.name .. "' first key has no bounds!")

		local bounds = slice.keys[1].bounds
		local s = {
			bounds = { x = bounds.x, y = bounds.y, w = bounds.w, h = bounds.h },
			quad = love.graphics.newQuad(bounds.x, bounds.y, bounds.w, bounds.h, self.image),
			color = self:__hexToColor(slice.color),
			data = slice.data
		}

		self.slices[slice.name] = s
	end
end

return peachy