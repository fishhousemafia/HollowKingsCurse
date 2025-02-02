if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  local lldebugger = require "lldebugger"
  lldebugger.start()
  local run = love.run
  function love.run(...)
    local debug = lldebugger.call(run, false, ...)
    return function(...)
      return lldebugger.call(debug, false, ...)
    end
  end
end

local Character = require "lib.Character"
local EventBus = require "lib.EventBus"
local ProjectileManager = require "lib.ProjectileManager"
local ServiceLocator = require "lib.ServiceLocator"
local Vector2 = require "lib.Vector2"

_G.SCALE_FACTOR = 1

local eventBus = ServiceLocator:register(EventBus)
local projectileManager = ServiceLocator:register(ProjectileManager)
local hero = nil ---@type Character
local lastAttack = nil

function love.load()
  local gameDimensions = Vector2.new(320, 240)
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode((gameDimensions * _G.SCALE_FACTOR):tuple())

  hero = Character.new(gameDimensions / 2)

  eventBus:subscribe("attackRequest", function(attackVectors)
    lastAttack = attackVectors
    hero.weapon:attack(attackVectors.source, attackVectors.destination)
  end)

  eventBus:subscribe("projectileFired", function(projectile)
    projectileManager:add(projectile)
  end)
end

function love.keypressed(key)
  if key == "q" then
    love.event.quit()
  end
end

function love.update(dt)
  eventBus:emit("update", dt)

  projectileManager:evaluate(dt)
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  local x, y = (hero.position:floor() * _G.SCALE_FACTOR):tuple()
  local w, h = (Vector2.new(8, 8) * _G.SCALE_FACTOR):tuple()
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(1, 0, 0)
  if lastAttack then
    local x1, y1 = (lastAttack.source:floor() * _G.SCALE_FACTOR):tuple()
    local x2, y2 = (lastAttack.destination:floor() * _G.SCALE_FACTOR):tuple()
    love.graphics.line(x1, y1, x2, y2)
  end

  for projectile in projectileManager:iterate() do
    x, y = (projectile.position:floor() * _G.SCALE_FACTOR):tuple()
    w, h = _G.SCALE_FACTOR, _G.SCALE_FACTOR
    love.graphics.rectangle("fill", x, y, w, h)
  end

  love.graphics.setColor(1, 1, 0)
  love.graphics.print(string.format("FPS: %d", love.timer.getFPS()))
end
