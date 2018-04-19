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

function aseprite.new(dataFile)
	local self = setmetatable({}, aseprite)

	-- Read the data
	self._jsonData = json.decode(love.filesystem.read(dataFile))

	-- Load the image
	self.image = love.graphics.newImage(self._jsonData.meta.image)

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

	self.paused = false
	self:nextFrame()

	return self
end

function aseprite:_checkImageSize()
	local imageWidth, imageHeight = self._jsonData.meta.size.w, self._jsonData.meta.size.h
	assert(imageWidth == self.image:getWidth(), "Image width metadata doesn't match actual width of file")
	assert(imageHeight == self.image:getHeight(), "Image height metadata doesn't match actual height of file")
end

function aseprite:draw(x, y)
	if not self.currentFrame then
		error("No currentFrame to draw!")
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
	-- If currentFrameIndex isn't set then default to 1
	self.currentFrameIndex = (self.currentFrameIndex or 0) + 1

	-- Looping
	if self.currentFrameIndex > #self.frames then
		self.currentFrameIndex = 1
	end

	-- Get next frame
	self.currentFrame = self.frames[self.currentFrameIndex]

	self.frameTimer = cron.after(self.currentFrame.duration, self.nextFrame, self)
end

function aseprite:pause()
	self.paused = true
end

function aseprite:play()
	self.paused = false
end

return aseprite