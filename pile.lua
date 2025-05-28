-- Pile

require "vector"
local Constants = require("constants")

PileClass = {}

function PileClass:new(x, y, pileType)
  local pile = {}
  local metadata = {__index = PileClass}
  setmetatable(pile, metadata)
  
  pile.position = Vector(x, y)
  pile.cards = {}
  pile.type = pileType -- Possible types: deck, hand, board, discard
  pile.size = Vector(Constants.PILE_WIDTH, Constants.PILE_HEIGHT)
  -- pile.verticalOffset = 100
  
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
  -- Outline
  if self.type ~= "hand" then 
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.position.x - Constants.PADDING_X, self.position.y - Constants.PADDING_Y, Constants.PILE_WIDTH, Constants.PILE_HEIGHT, Constants.PILE_RADIUS, Constants.PILE_RADIUS)
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
  end
end

function PileClass:addCard(card)
  table.insert(self.cards, card)
  self:updateCardPositions()
  -- Modify size when pile takes new cards
  if self.type == "board" and #self.cards > 1 then 
    self.size.y = self.size.y + self.verticalOffset
    print("adding " .. tostring(self.verticalOffset))
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
  if self.type == "foundation" then
    -- for i, card in ipairs(self.cards) do
    --   card.targetPosition = Vector(self.position.x, self.position.y)
    -- end

  elseif self.type == "board" then
    for i, card in ipairs(self.cards) do
      local newPos = Vector(
        self.position.x,
        self.position.y + (i - 1) * self.verticalOffset
      )
      card.targetPosition = newPos
      card:setBasePosition(newPos.x, newPos.y)

      -- Reasign z position
      card.zOrder = i
  
      if i == #self.cards then
        -- card:setFaceUp()
        -- do nothing
      else
        -- card:setFaceDown()
      end
    end

  -- Pile is stock, solved card constraint does not apply
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
        card.faceUp = true
      else
        newPos = Vector(self.position.x, self.position.y)
        card.faceUp = true
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

-- Foundation pile (takes cards in order)
FoundationPile = {}
setmetatable(FoundationPile, {__index = PileClass})

function FoundationPile:new(x, y, suit)
  local pile = PileClass:new(x, y, "foundation")
  local metadata = {__index = FoundationPile}
  setmetatable(pile, metadata)
  
  pile.suit = suit
  
  return pile
end

function FoundationPile:acceptCards(cards, sourcePile)
  if #cards ~= 1 then
    return false
  end

  local top = #sourcePile.cards

  local card = cards[1]
  if card.suit ~= self.suit then
    return false
  end

  if #self.cards == 0 then
    if card.value == "ace" then
      self:addCard(card)
      card:release()

      if #sourcePile.cards > 0 and sourcePile.type ~= "foundation" then
        sourcePile.cards[top]:setFaceUp()
      end

      return true
    else
      return false
    end
  end

  local topCard = self:getTopCard()
  local topValue = topCard:getValue()
  local cardValue = card:getValue()

  if cardValue == topValue + 1 then
    self:addCard(card)
    card:release()

    -- Flip source pile card after valid move
    if #sourcePile.cards > 0 and sourcePile.type ~= "foundation" then
      sourcePile.cards[top]:setFaceUp()
    end

    return true
  end

  return false
end

-- Tableau pile (takes cards, offsets and faces all cards down except top)
TableauPile = {}
setmetatable(TableauPile, {__index = PileClass})

function TableauPile:new(x, y, index)
  local pile = PileClass:new(x, y, "tableau")
  local metadata = {__index = TableauPile}
  setmetatable(pile, metadata)
  
  pile.index = index
  pile.verticalOffset = 30
  
  return pile
end

function TableauPile:acceptCards(cards, sourcePile)
  local top = #sourcePile.cards

  if #self.cards == 0 then
    local firstCard = cards[1]
    if firstCard.value == "king" then
      for _, card in ipairs(cards) do
        self:addCard(card)
        card:release()
      end
      firstCard:setSolved()

      local allSolved = true

      if #sourcePile.cards > 1 and sourcePile.type ~= "waste" then
        for _, card in ipairs(sourcePile.cards) do
          print(tostring(card.suit) .. " " .. tostring(card.value) .. " " .. tostring(card.solved))
          if card.solved == false then
            allSolved = false
          end
        end
        if not allSolved then
          sourcePile.cards[top]:setFaceUp()
        end
      end

      return true
    else
      return false
    end
  end

  local topCard = self:getTopCard() -- Top of tableau
  local firstCard = cards[1] -- Held card

  if firstCard:getValue() == topCard:getValue() - 1 -- then
    and (topCard:isRed() and firstCard:isBlack() or topCard:isBlack() and firstCard:isRed()) then
    for _, card in ipairs(cards) do
      self:addCard(card)
      card:release()
    end

    firstCard:setSolved()
    topCard:setSolved()
    
    -- Flip sourcePile top card up after a valid move
    if #sourcePile.cards > 0 then
      sourcePile.cards[top]:setFaceUp()
    end
    return true
  end

  return false
end

-- Stock pile (drawing cards from)
StockPile = {}
setmetatable(StockPile, {__index = PileClass})

function StockPile:new(x, y, wastePile)
  local pile = PileClass:new(x, y, "stock")
  local metadata = {__index = StockPile}
  setmetatable(pile, metadata)
  
  pile.wastePile = wastePile
  
  return pile
end

function StockPile:draw()
  if not resetImage then
    resetImage = self:loadImage()
  end

  love.graphics.setColor(0, 0, 0, 0.3)
  love.graphics.rectangle("line", self.position.x - Constants.PADDING_X, self.position.y - Constants.PADDING_Y, Constants.PILE_WIDTH, Constants.PILE_HEIGHT, Constants.PILE_RADIUS, Constants.PILE_RADIUS)
  
  if #self.cards > 0 then
    self.cards[#self.cards]:draw()
    
    if #self.cards > 1 then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(#self.cards, self.position.x + 44, self.position.y + 65)
    end
  else
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.draw(resetImage, self.position.x, self.position.y)
  end
end

function StockPile:onClick()
  if #self.cards == 0 then
    while #self.wastePile.cards > 0 do
      local card = table.remove(self.wastePile.cards)
      card.faceUp = false
      table.insert(self.cards, card)
    end
    self:updateCardPositions()
    self.wastePile:updateCardPositions()
  else
    local cardsToMove = math.min(3, #self.cards)
    for i = 1, cardsToMove do
      local card = table.remove(self.cards)
      card.faceUp = true
      table.insert(self.wastePile.cards, card)
    end
    self:updateCardPositions()
    self.wastePile:updateCardPositions()
  end
  
  return true
end

-- Deck
DeckPile = {}
setmetatable(DeckPile, {__index = PileClass})

function DeckPile:new(x, y, handPile)
  local pile = PileClass:new(x, y, "deck")
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

function HandPile:new(x, y)
  local pile = PileClass:new(x, y, "hand")
  local metadata = {__index = HandPile}
  setmetatable(pile, metadata)
  
  pile.horizontalOffset = 70
  -- pile.size.x = pile.size.x + 3 * horizontalOffset
  
  return pile
end

function HandPile:getCardAt(mousePos)
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

-- Board
BoardPile = {}
setmetatable(BoardPile, {__index = PileClass})

function BoardPile:new(x, y, index, player)
  local pile = PileClass:new(x, y, "board")
  local metadata = {__index = BoardPile}
  setmetatable(pile, metadata)
  
  pile.index = index
  pile.player = player or "ai"
  pile.verticalOffset = 30
  -- pile.verticalOffset = 120
  
  return pile
end

function BoardPile:acceptCards(cards, sourcePile)
  if #self.cards >= 4 then
    return false
  else
    for _, card in ipairs(cards) do
      self:addCard(card)
      -- card:setFaceDown()
      card:release()
    end
  end

  return true
end

-- Waste
WastePile = {}
setmetatable(WastePile, {__index = PileClass})

function WastePile:new(x, y)
  local pile = PileClass:new(x, y, "waste")
  local metadata = {__index = WastePile}
  setmetatable(pile, metadata)
  
  pile.horizontalOffset = 20
  pile.size.x = pile.size.x + 3 * 20
  
  return pile
end

function WastePile:getCardAt(mousePos)
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
