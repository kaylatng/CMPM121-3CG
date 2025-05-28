-- Kayla Nguyen
-- CMPM 121 - 3CG
-- 5-19-25

-- Main

io.stdout:setvbuf("no")

require "card"
require "grabber"
require "pile"
require "game"
local Constants = require("constants")

-- local background = {0.78, 0.85, 0.94, 0.8} -- sky blue
local background = {0.38, 0.5, 0.47, 0.8} -- dark green
local font

function love.load()
  love.window.setMode(Constants.WINDOW_WIDTH, Constants.WINDOW_HEIGHT)
  love.window.setTitle("3CG") -- kairos
  love.graphics.setBackgroundColor(background)

  font = love.graphics.newFont("assets/slkscr.ttf", 20)
  love.graphics.setFont(font)
  
  -- math.randomseed(os.time())
  
  game = GameManager:new()
  game:initialize()
end

function love.update(dt)
  game:update(dt)
end

function love.draw()
  game:draw()
end

function love.mousepressed(x, y, button)
  game:mousePressed(x, y, button)
end

function love.mousereleased(x, y, button)
  game:mouseReleased(x, y, button)
end

function love.keypressed(key)
  if key == "q" then
    -- Quit game
    love.event.quit()
  end
end
