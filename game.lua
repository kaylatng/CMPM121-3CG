-- Game Manager

require "vector"
require "card"
require "pile"
require "selector"
require "button"

local Constants = require ("constants")
local Data = require ("data")

GameManager = {}

function GameManager:new()
  local game = {}
  local metadata = {__index = GameManager}
  setmetatable(game, metadata)

  game.piles = {}
  game.selector = SelectorClass:new()
  game.isInitialized = false
  game.moves = 0
  game.won = false
  game.state = Constants.GAME_STATE.YOUR_TURN

  game.endTurnButton = ButtonClass:new(game.state)
  
  return game
end

function GameManager:initialize()
  if self.isInitialized then return end

  local hand = HandPile:new(900, 800)
  table.insert(self.piles, hand)

  local stock = DeckPile:new(40, 800, hand)
  table.insert(self.piles, stock)

  local deck = self:createDeck()
  self:dealCards(deck, hand, self.piles)

  -- player board
  for i = 1, 4 do
    local boardPile = BoardPile:new(400 + (i-1) * 130, 400, i)
    table.insert(self.piles, boardPile)
  end

  -- ai board
  for i = 1, 4 do
    local boardPile = BoardPile:new(400 + (i-1) * 130, 100, i, "ai")
    table.insert(self.piles, boardPile)
  end

  self.isInitialized = true
end

function GameManager:createDeck()
  local deck = {}

  for i, entity in ipairs(Data) do
    for count = 1, 2 do
      local card = CardClass:new(
        entity.name,
        entity.util,
        entity.cost,
        entity.power,
        entity.text,
        entity.id,
        40, 40)
      table.insert(deck, card)
    end
  end

  shuffle(deck)

  return deck
end

function GameManager:dealCards(deck, hand, piles)
  local stockPile = nil
  local handPile = hand

  for _, pile in ipairs(piles) do
    if pile.type == "deck" then
      stockPile = pile
    end
  end

  for _, card in ipairs(deck) do
    stockPile:addCard(card)
  end

  for i = 1, 3 do
    local card = stockPile:getTopCard()
    stockPile:removeCard(card)
    handPile:addCard(card)
    card:setFaceUp()
  end
end

function GameManager:update(dt)
  for _, pile in ipairs(self.piles) do
    pile:update(dt)
  end
  
  -- Update visual indicators for valid targets
  self:updateValidTargetHighlights()
end

function GameManager:updateValidTargetHighlights()
  -- Clear all highlights first
  for _, pile in ipairs(self.piles) do
    pile:setHighlighted(false)
  end
  
  -- Highlight valid targets if a card is selected
  if self.selector:hasSelection() then
    for _, pile in ipairs(self.piles) do
      if self.selector:isValidTarget(pile) then
        pile:setHighlighted(true)
      end
    end
  end
end

function GameManager:draw()
  self.endTurnButton:draw()

  for _, pile in ipairs(self.piles) do
    pile:draw()
  end

  -- Draw selection status
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print("Mouse: " .. tostring(love.mouse.getX()) .. ", " .. tostring(love.mouse.getY()))
  
  if self.selector:hasSelection() then
    local selectedCard = self.selector:getSelectedCard()
    love.graphics.setColor(0.2, 0.8, 1, 1)
    love.graphics.print("Selected: " .. selectedCard.name, 0, 20)
    love.graphics.print("Tap on a highlighted area to place the card", 0, 40)
  else
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.print("Tap on a card to select it", 0, 20)
  end
end

function GameManager:mousePressed(x, y, button)
  local mousePos = Vector(x, y)

  -- Check end turn button
  if self.endTurnButton:checkForMouseOver(mousePos) then
    if self.endTurnButton:mousePressed() then
      self.state = Constants.GAME_STATE.AI_TURN
      self.endTurnButton.gamestate = Constants.GAME_STATE.AI_TURN
      -- Clear any selection when ending turn
      self.selector:deselectCard()
    end
    return
  end

  -- Handle card selection and placement
  if self.selector:hasSelection() then
    -- Try to place the selected card
    local targetPile = self:getPileAt(mousePos)
    if targetPile and self.selector:tryPlaceCard(targetPile) then
      self.moves = self.moves + 1
      return
    else
      -- If clicked somewhere invalid, deselect the card
      self.selector:deselectCard()
    end
  else
    -- Try to select a card
    for _, pile in ipairs(self.piles) do
      if pile:checkForMouseOver(mousePos) then
        -- Handle deck click
        if pile.type == "deck" then
          pile:onClick()
          return
        end

        -- Try to select a card
        local card = pile:getCardAt(mousePos)
        if card and card.faceUp and pile.owner == "player" then
          self.selector:selectCard(card, pile)
          return
        end
      end
    end
  end
end

function GameManager:getPileAt(mousePos)
  for _, pile in ipairs(self.piles) do
    if pile:checkForMouseOver(mousePos) then
      return pile
    end
  end
  return nil
end

function GameManager:mouseReleased(x, y, button)
  local mousePosButton = Vector(x, y)

  if self.endTurnButton:checkForMouseOver(mousePosButton) then
    self.endTurnButton:mouseReleased()
  end
end

function shuffle(deck)
  local cardCount = #deck
  for i = 1, cardCount do
    local randIndex = math.random(cardCount)
    local temp = deck[randIndex]
    deck[randIndex] = deck[cardCount]
    deck[cardCount] = temp
    cardCount = cardCount -1
  end
  return deck
end