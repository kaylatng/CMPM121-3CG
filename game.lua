-- Game Manager

require "vector"
require "card"
require "pile"
require "grabber"

local Constants = require ("constants")
local Data = require ("data")

GameManager = {}

function GameManager:new()
  local game = {}
  local metadata = {__index = GameManager}
  setmetatable(game, metadata)

  game.piles = {}
  game.grabber = GrabberClass:new()
  game.isInitialized = false
  game.moves = 0
  game.won = false
  
  return game
end

function GameManager:initialize()
  if self.isInitialized then return end

  local hand = HandPile:new(900, 800)
  table.insert(self.piles, hand)

  local stock = DeckPile:new(40, 800, hand)
  table.insert(self.piles, stock)

  local deck = self:createDeck()
  self:dealCards(deck, self.piles)

  for i = 1, 4 do
    local boardPile = BoardPile:new(400 + (i-1) * 130, 400, i, "player")
    table.insert(self.piles, boardPile)
  end

  for i = 1, 4 do
    local boardPile = BoardPile:new(400 + (i-1) * 130, 100, i)
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
      -- print("Creating ".. tostring(entity.name))
      table.insert(deck, card)
    end
  end

  shuffle(deck)

  return deck
end

function GameManager:dealCards(deck, piles)
  local stockPile = nil

  for _, pile in ipairs(piles) do
    -- if pile.type == "tableau" then
    --   table.insert(tableauPiles, pile)
    -- else
    if pile.type == "deck" then
      stockPile = pile
    end
  end

  -- table.sort(tableauPiles, function(a, b) return a.index < b.index end)

  -- for i, pile in ipairs(tableauPiles) do
  --   for j = 1, i do
  --     local card = table.remove(deck)
  --     if j == i then
  --       card.faceUp = true
  --     end
  --     pile:addCard(card)
  --   end
  -- end

  for _, card in ipairs(deck) do
    stockPile:addCard(card)
  end
end

function GameManager:update(dt)
  self.grabber:update(dt)

  for _, pile in ipairs(self.piles) do
    pile:update(dt)
  end

end

function GameManager:draw()

  for _, pile in ipairs(self.piles) do
    pile:draw()
  end

  for _, card in ipairs(self.grabber.heldCards) do
    card:draw()
  end

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print("Mouse: " .. tostring(self.grabber.currentMousePos.x) .. ", " .. tostring(self.grabber.currentMousePos.y))
end

function GameManager:mousePressed(x, y, button)
  local mousePos = Vector(x, y)

  if self.grabber:isHoldingCards() then
    local targetPile = nil

    for _, pile in ipairs(self.piles) do
      if pile:checkForMouseOver(mousePos) then
        targetPile = pile
        break
      end
    end

    return
  else -- Not holding cards
    for _, pile in ipairs(self.piles) do
      if pile:checkForMouseOver(mousePos) then
        if pile.type == "deck" then
          if pile:onClick() then
          end
          return
        end
  
        local card = pile:getCardAt(mousePos)

        if card then
          if self.grabber:tryGrab(card, pile) then
            -- Sanity check
          end
          return
        end
      end
    end
  end
end

function GameManager:mouseReleased(x, y, button)
  local mousePosButton = Vector(x, y)

  if self.grabber:isHoldingCards() then
    local mousePos = Vector(x, y)
    local targetPile = nil

    for _, pile in ipairs(self.piles) do
      if pile:checkForMouseOver(mousePos) then
        targetPile = pile
        print(tostring(targetPile.type))
        break
      end
    end

    if self.grabber:tryRelease(targetPile) then
      self.moves = self.moves + 1
    end
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