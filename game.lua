-- Game Manager

require "vector"
require "card"
require "pile"
require "selector"
require "button"
require "mana"
require "score"

local Constants = require ("constants")
local Data = require ("data")

GameManager = {}

function GameManager:new()
  local game = {}
  local metadata = {__index = GameManager}
  setmetatable(game, metadata)

  game.piles = {}
  game.manas = {}
  game.scores = {}
  game.selector = SelectorClass:new()
  game.isInitialized = false
  game.moves = 0
  game.won = false
  game.state = Constants.GAME_STATE.YOUR_TURN
  game.round = 0
  game.roundStart = false

  game.endTurnButton = ButtonClass:new(game.state)
  game.canDraw = false
  game.winner = nil

  -- AI turn variables
  game.aiDuration = 1
  game.aiTimer = 1
  game.aiState = Constants.AI_STATE.IDLE

  -- Attack phase variables
  game.cardsRevealed = false
  game.attackDuration = 2
  game.attackTimer = 2

  return game
end

function GameManager:initialize()
  if self.isInitialized then return end

  -- Player
  local hand = HandPile:new(1300, 800)
  table.insert(self.piles, hand)

  local stock = DeckPile:new(40, 800, hand)
  table.insert(self.piles, stock)

  local deck = self:createDeck()
  self:dealCards(deck, hand, self.piles, "player")

  for i = 1, 4 do
    local boardPile = BoardPile:new(700 + (i-1) * 130, 400, i)
    table.insert(self.piles, boardPile)
  end

  local playerMana = ManaClass:new(80, 678)
  table.insert(self.manas, playerMana)

  local playerScore = ScoreClass:new(40, 590, "player")
  table.insert(self.scores, playerScore)

  -- AI
  local aiHand = HandPile:new(1300, 80, "ai")
  table.insert(self.piles, aiHand)

  local aiStock = DeckPile:new(40, 80, hand, "ai")
  table.insert(self.piles, aiStock)

  local aiDeck = self:createDeck()
  self:dealCards(aiDeck, aiHand, self.piles, "ai")

  for i = 1, 4 do
    local boardPile = BoardPile:new(700 + (i-1) * 130, 80, i, "ai")
    table.insert(self.piles, boardPile)
  end

  local aiMana = ManaClass:new(80, 305, "ai")
  table.insert(self.manas, aiMana)

  local aiScore = ScoreClass:new(40, 380, "ai")
  table.insert(self.scores, aiScore)

  -- Game variables
  self.round = 1
  self.isInitialized = true
  self.roundStart = true
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

function GameManager:dealCards(deck, hand, piles, owner)
  local stockPile = nil
  local handPile = hand

  for _, pile in ipairs(piles) do
    if pile.type == "deck" and pile.owner == owner then
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
    if owner == "player" then
      card:setFaceUp()
    else
      card:setFaceDown()
    end
  end
end

function GameManager:update(dt)
  for _, pile in ipairs(self.piles) do
    pile:update(dt)
  end
  
  -- Update visual indicators for valid targets
  self:updateValidTargetHighlights()

  -- Draw card at round start
  if self.roundStart then
    self:drawCardFor("player")
    self.roundStart = false
  end

  if self.state == Constants.GAME_STATE.AI_TURN then
    if self.aiState == Constants.AI_STATE.IDLE then
      self.aiTimer = self.aiTimer - dt
      if self.aiTimer <= 0 then
        self.aiState = Constants.AI_STATE.ACTIVE
        self.aiTimer = self.aiDuration
      end
    elseif self.aiState == Constants.AI_STATE.ACTIVE then
      self:aiTurn()
      self.aiState = Constants.AI_STATE.IDLE
    end
  elseif self.state == Constants.GAME_STATE.ATTACK then
    self:updateAttack(dt)
  end

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

function GameManager:updateAttack(dt)
  self.attackTimer = self.attackTimer - dt
  
  if self.attackTimer <= 0 then
    if not self.cardsRevealed then
      self:revealAllBoardCards()
      self.cardsRevealed = true
      self.attackTimer = self.attackDuration
      self.endTurnButton.gamestate = Constants.GAME_STATE.ATTACK
    else
      self:attack()
      self.attackTimer = self.attackDuration
    end
  end
end

function GameManager:revealAllBoardCards()
  -- Reveal all cards on board piles
  for _, pile in ipairs(self.piles) do
    if pile.type == "board" then
      for _, card in ipairs(pile.cards) do
        card:setFaceUp()
      end
    end
  end
  
  print("Cards revealed! Battle begins...")
end

function GameManager:draw()
  self.endTurnButton:draw()

  for _, pile in ipairs(self.piles) do
    pile:draw()
  end

  for _, mana in ipairs(self.manas) do
    mana:draw()
  end

  for _, score in ipairs(self.scores) do
    score:draw()
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

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print("ROUND: " .. tostring(self.round), 40, Constants.WINDOW_HEIGHT / 2 - 25)
end

function GameManager:mousePressed(x, y, button)
  local mousePos = Vector(x, y)
  local mp
  
  -- Get player mana
  for _, mana in ipairs(self.manas) do
    if mana.owner == "player" then
      mp = mana.mp
    end
  end

  -- Check end turn button
  if self.endTurnButton:checkForMouseOver(mousePos) then
    if self.endTurnButton:mousePressed() and self.state == Constants.GAME_STATE.YOUR_TURN then

      -- Flip player cards to back
      for _, pile in ipairs(self.piles) do
        if pile.type == "board" and pile.owner == "player" then
          for _, card in ipairs(pile.cards) do
            if not card.active then
              card:setFaceDown()
              card.active = true
            end
          end
        end
      end

      self:drawCardFor("ai")
      self.state = Constants.GAME_STATE.AI_TURN
      self.endTurnButton.gamestate = Constants.GAME_STATE.AI_TURN

      self.selector:deselectCard()
    end
    return
  end

  -- Handle card selection and placement
  if self.selector:hasSelection() then
    local targetPile = self:getPileAt(mousePos)
    local selectedCard = self.selector:getSelectedCard()
    
    if targetPile and self.selector:tryPlaceCard(targetPile) then
      if not selectedCard.wasPlaced then
        for _, mana in ipairs(self.manas) do
          if mana.owner == "player" then
            mana:useMana(selectedCard.cost)
          end
        end
      end
      selectedCard.wasPlaced = true
      self.moves = self.moves + 1
      return
    else
      self.selector:deselectCard()
    end
  else -- Nothing selected
    for _, pile in ipairs(self.piles) do
      if pile:checkForMouseOver(mousePos) and pile.owner == "player" then
        if pile.type == "deck" and self.canDraw then
          pile:onClick()
          return
        end

        -- Try to select a card
        local card = pile:getCardAt(mousePos)
        if card and card.faceUp then
          -- Card was played before, mana cost paid
          if card.wasPlaced then 
            self.selector:selectCard(card, pile)
          elseif card.cost <= mp then
            self.selector:selectCard(card, pile)
          else -- Not enough mana
            -- TODO: add visual tween
            print("Not enough mana")
          end
          return
        else
          -- DO NOTHING
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

function GameManager:aiTurn()
  local deckPile, handPile, aiMan = nil
  local boardPiles = {}

  for _, pile in ipairs(self.piles) do
    if pile.owner == "ai" then
      if pile.type == "deck" then
        deckPile = pile
      elseif pile.type == "hand" then
        handPile = pile
      elseif pile.type == "board" then
         table.insert(boardPiles, pile)
      end
    end
  end

  for _, mana in ipairs(self.manas) do
    if mana.owner == "ai" then
      aiMana = mana
    end
  end

  local cardsToPlay = {}
  local cardCostTotal = 0
  for _, card in ipairs(handPile.cards) do
    -- cardCostTotal = cardCostTotal + card.cost
    if card.cost <= aiMana.mp and not card.wasPlaced then
      table.insert(cardsToPlay, card)
      aiMana:useMana(card.cost)
    end
    -- TODO: modify depending on difficulty
    -- if #cardsToPlay >= 3 then break end
    if aiMana.mp == 0 then break end
  end

  for i, card in ipairs(cardsToPlay) do
    for _, boardPile in ipairs(boardPiles) do
      if #boardPile.cards < 4 then
        boardPile:addCard(card)
        card.wasPlaced = true
        -- card:setFaceUp()
        card:setFaceDown()
        -- aiMana:useMana(card.cost)
        handPile:removeCard(card)
        break
      end
    end
  end

  self.state = Constants.GAME_STATE.ATTACK
end

function GameManager:attack()
  print("Attack in progress...")
  
  -- Get board piles for both players
  local playerBoardPiles = {}
  local aiBoardPiles = {}
  
  for _, pile in ipairs(self.piles) do
    if pile.type == "board" then
      if pile.owner == "player" then
        table.insert(playerBoardPiles, pile)
      elseif pile.owner == "ai" then
        table.insert(aiBoardPiles, pile)
      end
    end
  end
  
  -- Battle logic: compare cards in each position
  for i = 1, math.min(#playerBoardPiles, #aiBoardPiles) do
    local playerPile = playerBoardPiles[i]
    local playerPileTotal = 0
      
    local aiPile = aiBoardPiles[i]
    print(tostring(#aiBoardPiles[i].cards))
    local aiPileTotal = 0

    for _, card in ipairs(playerPile.cards) do
      playerPileTotal = playerPileTotal + card.power
    end

    for _, card in ipairs(aiPile.cards) do
      aiPileTotal = aiPileTotal + card.power
      print("adding total of " .. tostring(card.name) .. " value: " .. tostring(card.power))
    end

    local playerCard = #playerPile.cards > 0 and playerPile.cards[1] or nil
    local aiCard = #aiPile.cards > 0 and aiPile.cards[1] or nil
    
    self:battleCards(playerPileTotal, aiPileTotal, playerPile, aiPile)
  end
  
  -- Reset for next round
  self.cardsRevealed = false
  self.state = Constants.GAME_STATE.YOUR_TURN
  self.endTurnButton.gamestate = Constants.GAME_STATE.YOUR_TURN
  self.roundStart = true
  self:nextRound()
end

function GameManager:battleCards(playerPower, aiPower, playerPile, aiPile)
  local playerPower = playerPower
  local aiPower = aiPower

  local points = 0
  self.winner = nil
  
  print("Battle: (" .. tostring(playerPower) .. ") vs (" .. tostring(aiPower) .. ")")
  
  if playerPower > aiPower then
    print("Player wins")
    points = playerPower - aiPower
    self.winner = "player"
  elseif aiPower > playerPower then
    print("AI wins")
    points = aiPower - playerPower
    self.winner = "ai"
  else
    print("Tie")
    -- TODO: resolve tie
  end

  for _, score in ipairs(self.scores) do
    if score.owner == self.winner then
      score:modifyScore(points)
    end
  end

end

function GameManager:drawCardFor(owner)
  local deckPile, handPile

  for _, pile in ipairs(self.piles) do
    if pile.owner == owner then
      if pile.type == "deck" then
        deckPile = pile
      elseif pile.type == "hand" then
        handPile = pile
      end
    end
  end

  if #handPile.cards >= 7 then return false end

  if deckPile and handPile and #deckPile.cards > 0 then
    local card = deckPile:getTopCard()
    if card then
      deckPile:removeCard(card)
      handPile:addCard(card)
      if owner == "player" then
        card:setFaceUp()
      else
        card:setFaceDown()
      end
    end
  end
end

function GameManager:revealAllBoardCards()
  for _, pile in ipairs(self.piles) do
    if pile.type == "board" then
      for _, card in ipairs(pile.cards) do
        card:setFaceUp()
      end
    end
  end
end

function GameManager:nextRound()
  self.round = self.round + 1

  for _, mana in ipairs(self.manas) do
    mana:setMana(self.round)
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
