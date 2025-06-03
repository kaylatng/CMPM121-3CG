-- Score

require "vector"
local Constants = require("constants")

ScoreClass = {}

function ScoreClass:new(xPos, yPos, owner)
  local score = {}
  local metadata = {__index = ScoreClass}
  setmetatable(score, metadata)

  score.position = Vector(xPos, yPos)
  score.size = Vector(200, 50)
  score.owner = owner or "player"
  score.value = 0

  return score
end

function ScoreClass:update(dt)

end

function ScoreClass:draw()
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf("SCORE: " .. tostring(self.value), self.position.x, self.position.y, self.size.x, "left")
end

function ScoreClass:setValue(value)
  self.value = value
end

function ScoreClass:modifyScore(amount)
  self.value = math.max(0, self.value + amount)
end