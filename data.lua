-- https://stackoverflow.com/questions/59803827/lua-getting-values-from-nested-table

-- Data

local Data = {

  {
    name = "Athena",
    util = "reactive",
    cost = 2,
    power = 3,
    text = "Gain +1 power when you play another card here.",
    id = 1,
  },
  {
    name = "Daedalus",
    util = "reveal",
    cost = 3,
    power = 3,
    text = "When Revealed: Add a Wooden Cow to each other location.",
    id = 2,
  },
  {
    name = "Hephaestus",
    util = "reveal",
    cost = 2,
    power = 4,
    text = "When Revealed: Lower the cost of 2 cards in your hand by 1.",
    id = 3,
  },
  {
    name = "Icarus",
    util = "end-turn",
    cost = 1,
    power = 1,
    text = "End of Turn: Gains +1 power, but is discarded when its power is greater than 7.",
    id = 4,
  }, 
  {
    name = "Demeter",
    util = "reveal",
    cost = 1,
    power = 2,
    text = "When Revealed: Both players draw a card.",
    id = 5,
  },
  {
    name = "Medusa",
    util = "reactive",
    cost = 5,
    power = 7,
    text = "When ANY other card is played here, lower that card's power by 1.",
    id = 6,
  },
  {
    name = "Persephone",
    util = "reveal",
    cost = 4,
    power = 5,
    text = "When Revealed: Discard the lowest power card in your hand.",
    id = 7,
  },
  {
    name = "Aphrodite",
    util = "reveal",
    cost = 4,
    power = 4,
    text = "When Revealed: Lower the power of each enemy card here by 1.",
    id = 8,
  },
  {
    name = "Wooden Cow",
    util = "vanilla",
    cost = 1,
    power = 1,
    text = "Vanilla",
    id = 9,
  },
  {
    name = "Ares",
    util = "reveal",
    cost = 6,
    power = 7,
    text = "When Revealed: Gain +2 power for each enemy card here.",
    id = 10,
  },
  {
    name = "Apollo",
    util = "reveal",
    cost = 1,
    power = 1,
    text = "When Revealed: Gain +1 mana next turn.",
    id = 11,
  },
}

return Data