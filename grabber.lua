-- Grabber

require "vector"

GrabberClass = {}

function GrabberClass:new()
  local grabber = {}
  local metadata = {__index = GrabberClass}
  setmetatable(grabber, metadata)
  
  grabber.previousMousePos = nil
  grabber.currentMousePos = nil
  
  grabber.grabPos = nil
  
  -- Keep track of the cards we're holding
  grabber.heldCards = {}
  grabber.sourcePile = nil
  
  return grabber
end

function GrabberClass:update(dt)
  self.previousMousePos = self.currentMousePos
  self.currentMousePos = Vector(
    love.mouse.getX(),
    love.mouse.getY()
  )
  
  -- Update positions of held cards
  for _, card in ipairs(self.heldCards) do
    card:moveWithMouse(self.currentMousePos)
  end
end

function GrabberClass:tryGrab(card, stack)
  if #self.heldCards > 0 then
    return false 
  end

  if not card.faceUp then
    return false
  end
  self.grabPos = self.currentMousePos

  local cardsToGrab = {} -- Grab pile
  if stack.type == "tableau" then
    local startIndex = nil
    for i, tableauCard in ipairs(stack.cards) do
      if tableauCard == card then
        startIndex = i
        break
      end
    end
    
    if startIndex then
      for i = startIndex, #stack.cards do
        table.insert(cardsToGrab, stack.cards[i])
      end
    end
  -- elseif stack.type == "hand" then
  --   local startIndex = nil
  --   for i, handCard in ipairs(stack.cards) do
  --     if handCard == card then
  --       startIndex = i
  --       break
  --     end
  --   end
    
  --   if startIndex then
  --     table.insert(cardsToGrab, card)
  --   end
  else -- Grab one card
    table.insert(cardsToGrab, card)
  end
  
  -- Set all cards to grabbed state
  for i, cardToGrab in ipairs(cardsToGrab) do
    cardToGrab:setGrabbed(self)
    table.insert(self.heldCards, cardToGrab)
  end
  
  self.sourcePile = stack
  
  -- Remove grabbed cards from source pile
  for _, cardToRemove in ipairs(cardsToGrab) do
    stack:removeCard(cardToRemove)
  end
  
  return true
end

function GrabberClass:tryRelease(targetPile)  
  if #self.heldCards == 0 then
    self.grabPos = nil
    return false
  end
  
  local success = false
  
  if targetPile then
    print("target pile is: " .. tostring(targetPile.type) .. " index: " .. tostring(targetPile.index))
    success = targetPile:acceptCards(self.heldCards, self.sourcePile)
  end
  
  if success then
    -- Cards were accepted by the target pile
    self.heldCards = {}
  else
    -- Return cards to the source pile
    if self.sourcePile then
      for _, card in ipairs(self.heldCards) do
        card:release()
        self.sourcePile:addCard(card)
      end
      self.heldCards = {}
    end
  end
  
  self.grabPos = nil
  self.sourcePile = nil
  return success
end

function GrabberClass:cancelDrag()
  if #self.heldCards == 0 then
    return
  end
  
  if self.sourcePile then
    for _, card in ipairs(self.heldCards) do
      card:release()
      self.sourcePile:addCard(card)
    end
  end
  
  self.heldCards = {}
  self.grabPos = nil
  self.sourcePile = nil
end

function GrabberClass:isHoldingCards()
  return #self.heldCards > 0
end