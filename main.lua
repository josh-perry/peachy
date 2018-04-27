local aseprite = require("aseprite")

local count
local colours
local countReverse
local countPingPong
local spinner
local spriteSheet
local man = require("examples/man")

function love.load()
  spriteSheet = love.graphics.newImage("examples/countAndColours.png")

  count = aseprite.new("examples/countAndColours.json", spriteSheet, "Numbers")
  colours = aseprite.new("examples/countAndColours.json", spriteSheet, "Colours")
  countReverse = aseprite.new("examples/countAndColours.json", spriteSheet, "NumbersDown")
  countPingPong = aseprite.new("examples/countAndColours.json", spriteSheet, "PingPong")

  spinner = aseprite.new("examples/spinner.json", love.graphics.newImage("examples/spinner.png"), "Spin")
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
  man.sprite:draw(man.x, man.y)

  love.graphics.print("spinner.json", 15, 415)
  love.graphics.print("Press space to pause/play", 50, 450)
  spinner:draw(50, 480)
end

function love.update(dt)
  count:update(dt)
  colours:update(dt)
  countReverse:update(dt)
  countPingPong:update(dt)
  spinner:update(dt)

  man:movement(dt)
  man.sprite:update(dt)
end

function love.keypressed(key)
  if key == "space" then
    spinner:togglePlay()
  end
end