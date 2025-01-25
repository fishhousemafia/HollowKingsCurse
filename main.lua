if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  local lldebugger = require("lldebugger")
  lldebugger.start()
  local run = love.run
  function love.run(...)
    local debug = lldebugger.call(run, false, ...)
    return function(...)
      return lldebugger.call(debug, false, ...)
    end
  end
end

_G.VEC_COUNT = 0

local Character = require("library/Character")
local EventBus = require("library/EventBus")
local MessageQueue = require("library/MessageQueue")
local ProjectileManager = require("library/ProjectileManager")
local ServiceLocator = require("library/ServiceLocator")
local Vector2 = require("library/Vector2")

local eventBus = ServiceLocator:register(EventBus)
local messageQueue = ServiceLocator:register(MessageQueue)
local projectileManager = ServiceLocator:register(ProjectileManager)
local hero = nil ---@type Character
local lastAttack = nil
local scaleFactor = 1
--local frameRate = 60

function love.load()
  local gameDimensions = Vector2.new(320, 240)
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  scaleFactor = math.min(scaled:tuple()) - 1
  love.window.setMode((gameDimensions * scaleFactor):tuple())

  hero = Character.new(gameDimensions / 2)

  eventBus:subscribe("moveRequest", function(moveVector)
    hero:move(moveVector)
  end)

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
  local speed = 60
  if love.keyboard.isDown("w") then
    messageQueue:push("moveRequest", Vector2.new(0, -1))
  end
  if love.keyboard.isDown("a") then
    messageQueue:push("moveRequest", Vector2.new(-1, 0))
  end
  if love.keyboard.isDown("s") then
    messageQueue:push("moveRequest", Vector2.new(0, 1))
  end
  if love.keyboard.isDown("d") then
    messageQueue:push("moveRequest", Vector2.new(1, 0))
  end
  if love.mouse.isDown(1) then
    eventBus:emit("attackRequest", {
      source = hero.position,
      destination = Vector2.new(love.mouse.getPosition()) / scaleFactor,
    })
  end

  local moveVector = Vector2.zero()
  for message in messageQueue:collect("moveRequest") do
    moveVector = moveVector + message
  end

  eventBus:emit("moveRequest", moveVector:unit() * (speed * dt))

  projectileManager:evaluate(dt)

  --if dt < 1/frameRate then
  --  love.timer.sleep(1/frameRate - dt)
  --end
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  local x, y = (hero.position:floor() * scaleFactor):tuple()
  local w, h = (Vector2.new(8, 8) * scaleFactor):tuple()
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(1, 0, 0)
  if lastAttack then
    local x1, y1 = (lastAttack.source:floor() * scaleFactor):tuple()
    local x2, y2 = (lastAttack.destination:floor() * scaleFactor):tuple()
    love.graphics.line(x1, y1, x2, y2)
  end

  for projectile in projectileManager:iterate() do
    x, y = (projectile.position:floor() * scaleFactor):tuple()
    w, h = scaleFactor, scaleFactor
    love.graphics.rectangle("fill", x, y, w, h)
  end

  love.graphics.setColor(1, 1, 0)
  love.graphics.print(string.format("FPS: %d", 1/love.timer.getDelta()))
  love.graphics.print(string.format("VEC_COUNT: %d", _G.VEC_COUNT), 0, 16)
  _G.VEC_COUNT = 0
end

