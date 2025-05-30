-- Selector

require "vector"

SelectorClass = {}

function SelectorClass:new()
  local selector = {}
  local metadata = {__index = SelectorClass}
  setmetatable(selector, metadata)
  
  selector.selectedCard = nil
  selector.sourcePile = nil
  selector.validTargets = {}
  
  return selector
end

function SelectorClass:selectCard(card, pile)
  if self.selectedCard then
    self.selectedCard:deselect()
  end
  
  self.selectedCard = card
  self.sourcePile = pile
  card:select()
  
  self:calculateValidTargets()
end

function SelectorClass:deselectCard()
  if self.selectedCard then
    self.selectedCard:deselect()
    self.selectedCard = nil
    self.sourcePile = nil
    self.validTargets = {}
  end
end

function SelectorClass:calculateValidTargets()
  self.validTargets = {}
  -- TODO: change valid targets
end

function SelectorClass:isValidTarget(pile)
  if not self.selectedCard or not pile then
    return false
  end
  
  -- Basic valid target
  if pile.type == "board" and pile.owner == self.sourcePile.owner then
    return #pile.cards < 4 -- Max 4
  end
  
  return false
end

function SelectorClass:tryPlaceCard(targetPile)
  if not self.selectedCard or not targetPile then
    return false
  end
  
  if self:isValidTarget(targetPile) then
    self.sourcePile:removeCard(self.selectedCard)
    targetPile:addCard(self.selectedCard)
    self.selectedCard:deselect()
    
    self.selectedCard = nil
    self.sourcePile = nil
    self.validTargets = {}
    
    return true
  end
  
  return false
end

function SelectorClass:hasSelection()
  return self.selectedCard ~= nil
end

function SelectorClass:getSelectedCard()
  return self.selectedCard
end