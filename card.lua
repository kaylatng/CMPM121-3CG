-- Card

require "vector"
local Constants = require("constants")

CardClass = {}

CARD_STATE = {
  IDLE = 0,
  MOUSE_OVER = 1,
  SELECTED = 2,
}

TYPE = {
  "vanilla",
  "reveal",
  "reactive",
  "end-turn",
  "discard"
}

SPRITESHEET_ROWS = 3
SPRITESHEET_COLUMNS = 5

local font

local cardSpritesheet, spritesheet = nil

function CardClass:new(name, cardType, cost, power, text, id, xPos, yPos, faceUp, inPlay)
  local card = {}
  local metadata = {__index = CardClass}
  setmetatable(card, metadata)
  
  card.name = name
  card.type = cardType
  card.cost = cost
  card.power = power
  card.text = text
  card.id = id

  card.position = Vector(xPos, yPos)
  card.targetPosition = Vector(xPos, yPos)
  card.basePosition = Vector(xPos, yPos)
  card.size = Vector(Constants.CARD_WIDTH, Constants.CARD_HEIGHT)

  card.faceUp = faceUp or false
  card.inPlay = inPlay or false
  card.wasPlaced = false
  card.active = false

  card.state = CARD_STATE.IDLE
  card.hoverOffset = 15
  card.selectOffset = 15
  card.zOrder = 0

  return card
end

function CardClass:update(dt)
  local x, y = love.mouse.getPosition()
  
  if self.state ~= CARD_STATE.SELECTED then
    if self:containsPoint(x, y) then
      self.state = CARD_STATE.MOUSE_OVER
    else
      self.state = CARD_STATE.IDLE
    end
    
    -- Update target position based on hover state
    if self.state == CARD_STATE.MOUSE_OVER and self.faceUp then
      self.targetPosition = Vector(self.basePosition.x, self.basePosition.y - self.hoverOffset)
    else
      self.targetPosition = Vector(self.basePosition.x, self.basePosition.y)
    end
  else
    -- When selected, keep elevated position
    self.targetPosition = Vector(self.basePosition.x, self.basePosition.y - self.selectOffset)
  end

  -- Smooth movement animation
  local distance = self.targetPosition - self.position
  if distance:length() > 1 then
    self.position = self.position + distance * 10 * dt
  else
    self.position = Vector(self.targetPosition.x, self.targetPosition.y)
  end
end

function CardClass:loadSpritesheet()
  if not cardSpritesheet then
    cardSpritesheet = love.graphics.newImage("assets/cards.png")
  end
  return cardSpritesheet
end

function CardClass:draw()
  spritesheet = self:loadSpritesheet()
  local text = false
  
  -- Draw drop shadow and selection glow
  if self.state ~= CARD_STATE.IDLE then
    love.graphics.setColor(0, 0, 0, 0.5)
    local offset = 4 * (self.state == CARD_STATE.SELECTED and 2 or 1)
    love.graphics.rectangle("fill", self.position.x + offset, self.position.y + offset, self.size.x, self.size.y, Constants.CARD_RADIUS, Constants.CARD_RADIUS)

    -- Selection glow effect
    if self.state == CARD_STATE.SELECTED then
      love.graphics.setColor(0.2, 0.8, 1, 0.6) -- Blue glow
      love.graphics.setLineWidth(4)
      love.graphics.rectangle("line", self.position.x - 2, self.position.y - 2, self.size.x + 4, self.size.y + 4, Constants.CARD_RADIUS, Constants.CARD_RADIUS)
      if self.faceUp then
        font = love.graphics.newFont("assets/slkscr.ttf", 20)
        love.graphics.setFont(font)
        text = true
      end
    end
  end
  
  love.graphics.setColor(1, 1, 1, 1)
  
  local quad
  local x

  if self.faceUp then
    local col = (self.id) % SPRITESHEET_COLUMNS
    local row = math.floor((self.id) / SPRITESHEET_COLUMNS)

    local x = col * Constants.CARD_WIDTH
    local y = row * Constants.CARD_HEIGHT
    
    quad = love.graphics.newQuad(x, y, Constants.CARD_WIDTH, Constants.CARD_HEIGHT, spritesheet:getDimensions())
  else
    -- Back img at [0, 0]
    local x = 0 * Constants.CARD_WIDTH
    local y = 0 * Constants.CARD_HEIGHT
    
    quad = love.graphics.newQuad(x, y, Constants.CARD_WIDTH, Constants.CARD_HEIGHT, spritesheet:getDimensions())
  end
  
  love.graphics.draw(spritesheet, quad, self.position.x, self.position.y)
  love.graphics.setColor(0, 0, 0, 1)

  if text then
    love.graphics.printf(tostring(self.name), Constants.WINDOW_WIDTH / 2 - 700, Constants.WINDOW_HEIGHT - 200, 200)
    love.graphics.printf(tostring(self.text), Constants.WINDOW_WIDTH / 2 - 700, Constants.WINDOW_HEIGHT - 150, 300)
  end

  font = love.graphics.newFont("assets/slkscr.ttf", 20)
  love.graphics.setFont(font)
  
  -- Debug info
  if self.state == CARD_STATE.SELECTED then
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.print("SELECTED", self.position.x + 5, self.position.y - 30)
  end
  love.graphics.setColor(0, 0, 0, 1)
end

function CardClass:setFaceUp()
  self.faceUp = true
end

function CardClass:setFaceDown()
  self.faceUp = false
end

function CardClass:containsPoint(x, y)
  return x > self.position.x and
  x < self.position.x + self.size.x and
  y > self.position.y and
  y < self.position.y + self.size.y
end

function CardClass:select()
  self.state = CARD_STATE.SELECTED
  self.zOrder = 100 -- Bring to front when selected
end

function CardClass:deselect()
  self.state = CARD_STATE.IDLE
  self.zOrder = 0
end

function CardClass:isSelected()
  return self.state == CARD_STATE.SELECTED
end

function CardClass:setBasePosition(x, y)
  self.basePosition = Vector(x, y)
  if self.state == CARD_STATE.IDLE then
    self.targetPosition = Vector(x, y)
  elseif self.state == CARD_STATE.MOUSE_OVER then
    self.targetPosition = Vector(x, y - self.hoverOffset)
  elseif self.state == CARD_STATE.SELECTED then
    self.targetPosition = Vector(x, y - self.selectOffset)
  end
end

function findIndex(table, value)
  for i, v in ipairs(table) do
    if v == value then
      return i
    end
  end
  return nil
end