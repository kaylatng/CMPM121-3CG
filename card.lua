-- Card

require "vector"
local Constants = require("constants")

CardClass = {}

CARD_STATE = {
  IDLE = 0,
  MOUSE_OVER = 1,
  GRABBED = 2,
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

function CardClass:new(name, cardType, cost, power, text, id, xPos, yPos, faceUp)
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

  card.state = CARD_STATE.IDLE
  card.dragOffset = Vector(0, 0)
  -- TODO: add hover
  card.hoverOffset = 30
  card.zOrder = 0

  return card
end

-- function CardClass:update(dt)
--   local x, y = love.mouse.getPosition()
--   if self:containsPoint(x, y) then
--     self.state = CARD_STATE.MOUSE_OVER
--   elseif not self:containsPoint(x,y) then
--     self.state = CARD_STATE.IDLE
--   end

--   -- Delay movement when let go
--   if self.state ~= CARD_STATE.GRABBED then
--     local distance = self.targetPosition - self.position
--     if distance:length() > 1 then
--       self.position = self.position + distance * 10 * dt
--     else
--       self.position = Vector(self.targetPosition.x, self.targetPosition.y)
--     end
--   end

--   if self.state == CARD_STATE.MOUSE_OVER and self.faceUp then
--     self.targetPosition = Vector(self.basePosition.x, self.basePosition.y - self.hoverOffset)
--   else
--     self.targetPosition = Vector(self.basePosition.x, self.basePosition.y)
--   end

--   print("POSITION: " .. tostring(self.position.x) .. " " .. tostring(self.position.y))
-- end

function CardClass:update(dt)
  local x, y = love.mouse.getPosition()
  local previousState = self.state
  
  if self.state ~= CARD_STATE.GRABBED then
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
  end

  -- Smooth movement animation
  if self.state ~= CARD_STATE.GRABBED then
    local distance = self.targetPosition - self.position
    if distance:length() > 1 then
      self.position = self.position + distance * 10 * dt
    else
      self.position = Vector(self.targetPosition.x, self.targetPosition.y)
    end
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
  
  -- Draw drop shadow for non-idle cards
  if self.state ~= CARD_STATE.IDLE then
    love.graphics.setColor(0, 0, 0, 0.5) -- color values [0, 1]
    local offset = 4 * (self.state == CARD_STATE.GRABBED and 2 or 1)
    love.graphics.rectangle("fill", self.position.x + offset, self.position.y + offset, self.size.x, self.size.y, Constants.CARD_RADIUS, Constants.CARD_RADIUS)

    if self.faceUp then
      font = love.graphics.newFont("assets/slkscr.ttf", 20)
      love.graphics.setFont(font)
      text = true
    end

  end
  
  love.graphics.setColor(1, 1, 1, 1)
  
  local quad
  local x

  if self.faceUp then
    -- local cardSuit = findIndex(SUITS, self.suit) - 1
    -- local cardValue = findIndex(CARD_VALUES, self.value) - 1

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
    love.graphics.printf(tostring(self.name), Constants.WINDOW_WIDTH / 2 - 450, Constants.WINDOW_HEIGHT - 200, 200)
    love.graphics.printf(tostring(self.text), Constants.WINDOW_WIDTH / 2 - 450, Constants.WINDOW_HEIGHT - 150, 300)
  end

  font = love.graphics.newFont("assets/slkscr.ttf", 20)
  love.graphics.setFont(font)
  
  -- Debug outline
  -- love.graphics.rectangle("line", self.position.x, self.position.y, self.size.x, self.size.y)

  -- Print card state
  love.graphics.print(tostring(self.state), self.position.x + 46, self.position.y - 20)
end

function CardClass:setFaceUp()
  self.faceUp = true
end

function CardClass:setFaceDown()
  self.faceUp = false
end

function CardClass:setSolved()
  self.faceUp = true
  self.solved = true
end

function CardClass:checkForMouseOver(grabber)
  if self.state == CARD_STATE.GRABBED then
    return false
  end

  local mousePos = grabber.currentMousePos
  local isMouseOver = 
    mousePos.x > self.position.x and
    mousePos.x < self.position.x + self.size.x and
    mousePos.y > self.position.y and
    mousePos.y < self.position.y + self.size.y

  if isMouseOver then
    self.state = CARD_STATE.MOUSE_OVER
    return true
  else
    self.state = CARD_STATE.IDLE
    return false
  end
end

function CardClass:containsPoint(x, y)
  return x > self.position.x and
  x < self.position.x + self.size.x and
  y > self.position.y and
  y < self.position.y + self.size.y
end

function CardClass:setGrabbed(grabber)
  self.state = CARD_STATE.GRABBED
  self.dragOffset = self.position - grabber.currentMousePos
  self.zOrder = 52  -- Bring to front while dragging
end

function CardClass:release()
  self.state = CARD_STATE.IDLE
  self.targetPosition = Vector(self.basePosition.x, self.basePosition.y)
end

function CardClass:moveWithMouse(mousePos)
  if self.state == CARD_STATE.GRABBED then
    self.position = mousePos + self.dragOffset
  end
end

function CardClass:setBasePosition(x, y)
  self.basePosition = Vector(x, y)
  if self.state == CARD_STATE.IDLE then
    self.targetPosition = Vector(x, y)
  elseif self.state == CARD_STATE.MOUSE_OVER then
    self.targetPosition = Vector(x, y - self.hoverOffset)
  end
end

function CardClass:isRed()
  return self.suit == "diamonds" or self.suit == "hearts"
end

function CardClass:isBlack()
  return self.suit == "clubs" or self.suit == "spades"
end

function CardClass:getValue()
  local values = {
    ace = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["10"] = 10,
    jack = 11,
    queen = 12,
    king = 13
  }
  
  return values[self.value]
end

function findIndex(table, value)
  for i, v in ipairs(table) do
    if v == value then
      return i
    end
  end
  return nil
end