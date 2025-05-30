-- Button

require "vector"
local Constants = require("constants")

ButtonClass = {}

BUTTON_STATE = {
  IDLE = 0,
  PRESSED = 1,
}

function ButtonClass:new(gamestate)
  local button = {}
  local metadata = {__index = ButtonClass}
  setmetatable(button, metadata)

  button.position = Vector(Constants.BUTTON_X, Constants.BUTTON_Y)
  button.size = Vector(Constants.BUTTON_WIDTH, Constants.BUTTON_HEIGHT)
  button.state = BUTTON_STATE.IDLE

  button.gamestate = gamestate

  return button
end

function ButtonClass:update(dt)

end

function ButtonClass:draw()
  if self.state ~= BUTTON_STATE.PRESSED then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("fill",
      Constants.BUTTON_X + 3, Constants.BUTTON_Y + 3,
      Constants.BUTTON_WIDTH, Constants.BUTTON_HEIGHT,
      Constants.BUTTON_RADIUS, Constants.BUTTON_RADIUS)
    love.graphics.rectangle("fill",
      Constants.BUTTON_X, Constants.BUTTON_Y,
      Constants.BUTTON_WIDTH, Constants.BUTTON_HEIGHT,
      Constants.BUTTON_RADIUS, Constants.BUTTON_RADIUS)
    -- love.graphics.setColor(0, 0, 0, 1)
    -- love.graphics.rectangle("line",
      -- Constants.BUTTON_X, Constants.BUTTON_Y,
      -- Constants.BUTTON_WIDTH, Constants.BUTTON_HEIGHT,
      -- Constants.BUTTON_RADIUS, Constants.BUTTON_RADIUS)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("END", Constants.BUTTON_X + 20, Constants.BUTTON_Y + 10)
  else 
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill",
      Constants.BUTTON_X + 3, Constants.BUTTON_Y + 3,
      Constants.BUTTON_WIDTH, Constants.BUTTON_HEIGHT,
      Constants.BUTTON_RADIUS, Constants.BUTTON_RADIUS)
    love.graphics.setColor(0, 0, 0, 1)

    love.graphics.print("END", Constants.BUTTON_X + 3 + 20, Constants.BUTTON_Y + 3 + 10)
  end

  love.graphics.setColor(0, 0, 0, 0.4)
  if self.gamestate == Constants.GAME_STATE.YOUR_TURN then
    love.graphics.printf("Planning phase", 0, Constants.WINDOW_HEIGHT - 60, Constants.WINDOW_WIDTH, "center")
  elseif self.gamestate == Constants.GAME_STATE.AI_TURN then
    love.graphics.printf("AI turn...", 0, Constants.WINDOW_HEIGHT - 60, Constants.WINDOW_WIDTH, "center")
  else -- Attack
    love.graphics.printf("Attack...", 0, Constants.WINDOW_HEIGHT - 60, Constants.WINDOW_WIDTH, "center")
  end

end

function ButtonClass:checkForMouseOver(mousePos)
  return mousePos.x > self.position.x and
         mousePos.x < self.position.x + self.size.x and
         mousePos.y > self.position.y and
         mousePos.y < self.position.y + self.size.y
end

function ButtonClass:mousePressed()
  self.state = BUTTON_STATE.PRESSED
  return true
end

function ButtonClass:mouseReleased()
  if self.state == BUTTON_STATE.PRESSED then
    self.state = BUTTON_STATE.IDLE
  end
end