local peachy = {
  _VERSION = "",
  _DESCRIPTION = "A parser/renderer for Aseprite animations in LÖVE.",
  _URL = "https://github.com/josh-perry/peachy",
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

local PATH = select('1', ...):match(".+%.") or ""
local json = require(PATH.."/lib/json")
local cron = require(PATH.."/lib/cron")

peachy.__index = peachy

function peachy.new(dataFile, imageData, initialTag)
  local self = setmetatable({}, peachy)

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

  self.paused = true

  self.tag = nil
  self.tagName = nil
  self.direction = nil

  if initialTag then
    self:setTag(initialTag)
    self.paused = false
  end

  return self
end

function peachy:_checkImageSize()
  local imageWidth, imageHeight = self._jsonData.meta.size.w, self._jsonData.meta.size.h
  assert(imageWidth == self.image:getWidth(), "Image width metadata doesn't match actual width of file")
  assert(imageHeight == self.image:getHeight(), "Image height metadata doesn't match actual height of file")
end

function peachy:setTag(tag)
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

function peachy:draw(x, y)
  if not self.frame then
    return
  end

  love.graphics.draw(self.image, self.frame.quad, x, y)
end

function peachy:update(dt)
  if self.paused then
    return
  end

  -- If we're trying to play an animation and it's nil or hasn't been set up
  -- properly then error
  assert(self.tag, "No animation tag has been set!")
  assert(self.frameTimer, "Frame timer hasn't been initialized!")

  -- Update timer in milliseconds since that's how Aseprite stores durations
  self.frameTimer:update(dt * 1000)
end

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
      self:_pingpongBounce()
    else
      self.frameIndex = 1
    end
  elseif not forward and self.frameIndex < 1 then
    if self.tag.direction == "pingpong" then
      self:_pingpongBounce()
    else
      self.frameIndex = #self.tag.frames
    end
  end

  -- Get next frame
  self.frame = self.tag.frames[self.frameIndex]

  self.frameTimer = cron.after(self.frame.duration, self.nextFrame, self)
end

function peachy:_pingpongBounce()
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

function peachy:pause()
  self.paused = true
end

function peachy:play()
  self.paused = false
end

function peachy:togglePlay()
  if self.paused then
    self:play()
  else
    self:pause()
  end
end

return peachy