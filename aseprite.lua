local aseprite = {
	_VERSION = "",
	_DESCRIPTION = "A parser/renderer for Aseprite animations in LÖVE.",
	_URL = "https://github.com/josh-perry",
	_LICENSE = [[
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

local json = require("lib/json")
local cron = require("lib/cron")

aseprite.__index = aseprite

function aseprite.new(dataFile, imageData, initialTag)
	local self = setmetatable({}, aseprite)

	-- Read the data
	self._jsonData = json.decode(love.filesystem.read(dataFile))

	-- Load the image
	self.image = imageData or love.graphics.newImage(self._jsonData.meta.image)

	self:_checkImageSize()

	-- Initialize all the quads
	self.frames = {}
	for _, frameData in ipairs(self._jsonData.frames) do
		local frame = {}

		local fd = frameData.frame
		frame.quad = love.graphics.newQuad(fd.x, fd.y, fd.w, fd.h, self._jsonData.meta.size.w, self._jsonData.meta.size.h)
		frame.duration = frameData.duration

		table.insert(self.frames, frame)
	end

	self.frameTags = {}
	for _, frameTag in ipairs(self._jsonData.meta.frameTags) do
		local ft = {}
		ft.direction = frameTag.direction
		ft.frames = {}

		for frame = frameTag.from + 1, frameTag.to + 1 do
			table.insert(ft.frames, self.frames[frame])
		end

		self.frameTags[frameTag.name] = ft
	end

	self.currentTag = nil
	self.currentDirection = nil

	if initialTag then
		self:setTag(initialTag)
	end

	self.paused = false

	return self
end

function aseprite:_checkImageSize()
	local imageWidth, imageHeight = self._jsonData.meta.size.w, self._jsonData.meta.size.h
	assert(imageWidth == self.image:getWidth(), "Image width metadata doesn't match actual width of file")
	assert(imageHeight == self.image:getHeight(), "Image height metadata doesn't match actual height of file")
end

function aseprite:setTag(tag)
	self.currentTag = self.frameTags[tag]
	self.currentFrameIndex = nil
	self.currentDirection = self.currentTag.direction

	if self.currentDirection == "pingpong" then
		self.currentDirection = "forward"
	end

	self:nextFrame()
end

function aseprite:draw(x, y)
	if not self.currentFrame then
		return
	end

	love.graphics.draw(self.image, self.currentFrame.quad, x, y)
end

function aseprite:update(dt)
	if self.paused then
		return
	end

	-- Update timer in milliseconds since that's how Aseprite stores durations
	self.frameTimer:update(dt * 1000)
end

function aseprite:nextFrame()
	local forward = self.currentDirection == "forward"

	if forward then
		self.currentFrameIndex = (self.currentFrameIndex or 0) + 1
	else
		self.currentFrameIndex = (self.currentFrameIndex or #self.currentTag.frames + 1) - 1
	end

	-- Looping
	if forward and self.currentFrameIndex > #self.currentTag.frames then
		if self.currentTag.direction == "pingpong" then
			self:_pingpongBounce()
		else
			self.currentFrameIndex = 1
		end
	elseif not forward and self.currentFrameIndex < 1 then
		if self.currentTag.direction == "pingpong" then
			self:_pingpongBounce()
		else
			self.currentFrameIndex = #self.currentTag.frames
		end
	end

	-- Get next frame
	self.currentFrame = self.currentTag.frames[self.currentFrameIndex]

	self.frameTimer = cron.after(self.currentFrame.duration, self.nextFrame, self)
end

function aseprite:_pingpongBounce()
	-- We need to increment/decrement frame index by 2 because
	-- at this point we've already gone to the next frame
	if self.currentDirection == "forward" then
		self.currentDirection = "reverse"
		self.currentFrameIndex = self.currentFrameIndex - 2
	else
		self.currentDirection = "forward"
		self.currentFrameIndex = self.currentFrameIndex + 2
	end
end

function aseprite:pause()
	self.paused = true
end

function aseprite:play()
	self.paused = false
end

return aseprite