-- Pile

require "vector"
local Constants = require("constants")

PileClass = {}

function PileClass:new(x, y, pileType, owner)
  local pile = {}
  local metadata = {__index = PileClass}
  setmetatable(pile, metadata)
  
  pile.position = Vector(x, y)
  pile.cards = {}
  pile.type = pileType -- deck, hand, board, discard
  pile.size = Vector(Constants.PILE_WIDTH, Constants.PILE_HEIGHT)

  pile.owner = owner or "player" -- ai or player
  pile.highlighted = false -- For showing valid drop targets
  
  return pile
end

function PileClass:update(dt)
  if self.type == "board" then
    local x, y = love.mouse.getPosition()
    local mousePos = Vector(x, y)

    if self:checkForMouseOver(mousePos) then
      self.verticalOffset = 120
    else
      self.verticalOffset = 30
    end

    self:updateCardPositions()
  end

  for i, card in ipairs(self.cards) do
    card:update(dt)
  end
end

function PileClass:draw()
  -- Highlight valid target piles
  if self.highlighted then
    love.graphics.setColor(0.3, 0.9, 0.3, 0.5) -- Green highlight
    love.graphics.rectangle("fill", self.position.x - Constants.PADDING_X - 2, self.position.y - Constants.PADDING_Y - 2, 
                           Constants.PILE_WIDTH + 4, Constants.PILE_HEIGHT + 4, Constants.PILE_RADIUS, Constants.PILE_RADIUS)
  end
  
  -- Outline
  if self.type ~= "hand" then 
    if self.highlighted then
      love.graphics.setColor(0.2, 0.8, 0.2, 0.8) -- Bright green border for valid targets
      love.graphics.setLineWidth(3)
    else
      love.graphics.setColor(0, 0, 0, 0.3)
      love.graphics.setLineWidth(2)
    end
    love.graphics.rectangle("line", self.position.x - Constants.PADDING_X, self.position.y - Constants.PADDING_Y, 
                           Constants.PILE_WIDTH, Constants.PILE_HEIGHT, Constants.PILE_RADIUS, Constants.PILE_RADIUS)
  end

  -- Cards
  for i, card in ipairs(self.cards) do
    card:draw()
  end

  if self.type == "board" then
    local total = 0
    for i, card in ipairs(self.cards) do
      total = total + card.power
    end
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(tostring(total), self.position.x + 46, self.position.y - 40)
    
    -- Show "DROP HERE" text for highlighted piles
    if self.highlighted then
      love.graphics.setColor(0.2, 0.8, 0.2, 1)
      love.graphics.print("DROP HERE", self.position.x - 6, self.position.y + Constants.PILE_HEIGHT + 5)
    end
  end

  love.graphics.origin()
end

function PileClass:setHighlighted(highlighted)
  self.highlighted = highlighted
end

function PileClass:addCard(card)
   for _, c in ipairs(self.cards) do
    if c == card then return false end
  end

  table.insert(self.cards, card)
  self:updateCardPositions()

  -- Modify size when pile takes new cards
  if self.type == "board" and #self.cards > 1 then 
    self.size.y = self.size.y + self.verticalOffset
  end

  if self.type == "hand" then 
    self.size.x = self.size.x + self.horizontalOffset
  end
  return true
end

function PileClass:removeCard(card)
  for i, pileCard in ipairs(self.cards) do
    if pileCard == card then
      table.remove(self.cards, i)
      self:updateCardPositions()

      if self.type == "board" then 
        self.size.y = self.size.y - self.verticalOffset
      end
      return true
    end
  end
  return false
end

-- Merged all functions to main pile class
function PileClass:updateCardPositions()
  if self.type == "board" then
    for i, card in ipairs(self.cards) do
      local newPos = Vector(
        self.position.x,
        self.position.y + (i - 1) * self.verticalOffset
      )
      card.targetPosition = newPos
      card:setBasePosition(newPos.x, newPos.y)

      -- Reasign z position
      card.zOrder = i
    end
  elseif self.type == "deck" then
    for i, card in ipairs(self.cards) do
      local newPos = Vector(self.position.x, self.position.y)
      card.targetPosition = newPos
      card:setBasePosition(newPos.x, newPos.y)
      card.faceUp = false
    end

  else -- Hand pile
    local visibleCards = math.min(7, #self.cards)

    for i = 1, #self.cards do
      local card = self.cards[i]
      local index = i - (#self.cards - visibleCards)

      if index > 0 then
        newPos = Vector(
          self.position.x + (index - 1) * self.horizontalOffset, 
          self.position.y
        )
        if self.owner == "ai" then
          card:setFaceDown()
        else
          card:setFaceUp()
        end
      else
        newPos = Vector(self.position.x, self.position.y)
        if self.owner == "ai" then
          card:setFaceDown()
        else
          card:setFaceUp()
        end
      end
      
      card.targetPosition = newPos
      card:setBasePosition(newPos.x, newPos.y)
    end
  end
end

function PileClass:getTopCard()
  if #self.cards > 0 then
    return self.cards[#self.cards]
  end
  return nil
end

function PileClass:acceptCards(cards, sourcePile)
  -- Returns false if the pile cannot accept cards
  -- return false
end

function PileClass:checkForMouseOver(mousePos)
  return mousePos.x > self.position.x and
         mousePos.x < self.position.x + self.size.x and
         mousePos.y > self.position.y and
         mousePos.y < self.position.y + self.size.y
end

function PileClass:getCardAt(mousePos)
  for i = #self.cards, 1, -1 do
    local card = self.cards[i]
    if mousePos.x > card.position.x and
       mousePos.x < card.position.x + card.size.x and
       mousePos.y > card.position.y and
       mousePos.y < card.position.y + card.size.y then
      return card
    end
  end
  return nil
end

-- Deck
DeckPile = {}
setmetatable(DeckPile, {__index = PileClass})

function DeckPile:new(x, y, handPile, owner)
  local pile = PileClass:new(x, y, "deck", owner)
  local metadata = {__index = DeckPile}
  setmetatable(pile, metadata)

  pile.handPile = handPile

  return pile
end

function DeckPile:draw()
  love.graphics.setColor(0, 0, 0, 0.3)
  love.graphics.rectangle("line", self.position.x - Constants.PADDING_X, self.position.y - Constants.PADDING_Y, Constants.PILE_WIDTH, Constants.PILE_HEIGHT, Constants.PILE_RADIUS, Constants.PILE_RADIUS)
  
  if #self.cards > 0 then
    self.cards[#self.cards]:draw()
    
    if #self.cards > 1 then
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.print(#self.cards, self.position.x + 44, self.position.y + 65)
    end
  end
end

function DeckPile:onClick()
  if self.owner == "ai" then return end

  local cardsToMove = math.min(1, #self.cards)

  if #self.handPile.cards >= 7 then
    return false
  else
    for i = 1, cardsToMove do
      local card = table.remove(self.cards)
      card.faceUp = true
      table.insert(self.handPile.cards, card)
    end
    self:updateCardPositions()
    self.handPile:updateCardPositions()

    self.handPile.size.x = self.handPile.size.x + self.handPile.horizontalOffset
  end

  return true
end

-- Hand
HandPile = {}
setmetatable(HandPile, {__index = PileClass})

function HandPile:new(x, y, owner)
  local pile = PileClass:new(x, y, "hand", owner)
  local metadata = {__index = HandPile}
  setmetatable(pile, metadata)
  
  pile.horizontalOffset = 70
  
  return pile
end

-- Board
BoardPile = {}
setmetatable(BoardPile, {__index = PileClass})

function BoardPile:new(x, y, index, owner)
  local pile = PileClass:new(x, y, "board", owner)
  local metadata = {__index = BoardPile}
  setmetatable(pile, metadata)
  
  pile.index = index
  pile.verticalOffset = 30
  
  return pile
end

function BoardPile:acceptCards(cards, sourcePile)
  if sourcePile.owner ~= self.owner then return false end
  
  if #self.cards >= 4 then
    return false
  else
    for _, card in ipairs(cards) do
      sourcePile:removeCard(card)
      self:addCard(card)
      card:deselect() -- Make sure card is deselected when placed
    end
  end

  return true
end

function BoardPile:getIndex()
  return self.index
end

-- Discard
DiscardPile = {}
setmetatable(DiscardPile, {__index = PileClass})

function DiscardPile:new(x, y, owner)
  local pile = PileClass:new(x, y, "discard", owner)
  local metadata = {__index = DiscardPile}
  setmetatable(pile, metadata)
  
  pile.horizontalOffset = 20
  pile.size.x = pile.size.x + 3 * 20
  
  return pile
end

function DiscardPile:getCardAt(mousePos)
  if #self.cards > 0 then
    local topCard = self.cards[#self.cards]
    if mousePos.x > topCard.position.x and
       mousePos.x < topCard.position.x + topCard.size.x and
       mousePos.y > topCard.position.y and
       mousePos.y < topCard.position.y + topCard.size.y then
      return topCard
    end
  end
  return nil
end