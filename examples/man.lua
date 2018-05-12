local peachy = require("peachy")

local man = {}

function man:movement(dt)
  self.sprite:play()

  if love.keyboard.isDown("left") then
    self.x = self.x - (self.speed * dt)
    self.sprite:setTag("WalkLeft")
  elseif love.keyboard.isDown("right") then
    self.x = self.x + (self.speed * dt)
    self.sprite:setTag("WalkRight")
  elseif love.keyboard.isDown("up") then
    self.y = self.y - (self.speed * dt)
    self.sprite:setTag("WalkUp")
  elseif love.keyboard.isDown("down") then
    self.y = self.y + (self.speed * dt)
    self.sprite:setTag("WalkDown")
  else
    self.sprite:pause()
  end
end

man.speed = 80
man.x, man.y = 50, 280
man.sprite = peachy.new("examples/man.json", love.graphics.newImage("examples/man.png"), "WalkDown")

return man