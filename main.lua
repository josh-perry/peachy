local peachy = require("peachy")

local count
local colours
local countReverse
local countPingPong
local spinner
local spriteSheet
local man = require("examples/man")

local blip

function love.load()
  love.window.setTitle("Peachy example - 🍑")
  spriteSheet = love.graphics.newImage("examples/countAndColours.png")

  count = peachy.new("examples/countAndColours.json", spriteSheet, "Numbers")
  colours = peachy.new("examples/countAndColours.json", spriteSheet, "Colours")
  countReverse = peachy.new("examples/countAndColours.json", spriteSheet, "NumbersDown")
  countPingPong = peachy.new("examples/countAndColours.json", spriteSheet, "PingPong")
  spinner = peachy.new("examples/spinner.json", love.graphics.newImage("examples/spinner.png"), "Spin")

  countPingPong:onLoop(function() print("Hey I'm in pingpong mode!") end)
  countReverse:onLoop(function() print("Hey I'm in reverse mode!") end)
  spinner:onLoop(function(a,b,c)
  	print("I'm spinning!")
  	print(("My arguments:%i %i %i"):format(a,b,c))
  end, 1,2,3)

  sound = peachy.new("examples/sound.json", love.graphics.newImage("examples/sound.png"), "Bounce")
  blip = love.audio.newSource("examples/blip.wav", "static")
  blip:setVolume(0.3)
end

function love.draw()
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
  love.graphics.print("Frame "..man.sprite.frameIndex, man.x, man.y + 60)
  man.sprite:draw(man.x, man.y)

  love.graphics.print("spinner.json", 15, 415)
  love.graphics.print("Press space to pause/play", 50, 450)
  spinner:draw(50, 480)

  love.graphics.print("sound.json", 415, 215)
  love.graphics.print("Press space to pause/play", 450, 250)
  sound:draw(450, 280)
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
  end
end
