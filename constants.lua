-- Constants

local Constants = {

  PADDING_X = 5,
  PADDING_Y = 5,

  PILE_WIDTH = 114,
  PILE_HEIGHT = 164,
  PILE_RADIUS = 6,

  CARD_WIDTH = 104,
  CARD_HEIGHT = 154,
  CARD_RADIUS = 8,

  WINDOW_WIDTH = 1920,
  WINDOW_HEIGHT = 1020,

  BUTTON_X = 37,
  BUTTON_Y = 740,
  BUTTON_WIDTH = 80,
  BUTTON_HEIGHT = 40,
  BUTTON_RADIUS = 20,

  GAME_STATE = {
  YOUR_TURN = 0,
  AI_TURN = 1,
  ATTACK = 2,
  },

  AI_STATE = {
    IDLE = 0,
    ACTIVE = 1,
  },

}

return Constants