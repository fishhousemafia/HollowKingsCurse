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
local gameDimensions = Vector2.new(320, 240)
local hero = Character.new(gameDimensions / 2)
local lastAttack = nil
local camera = Vector2.zero()
local center = (gameDimensions / 2):floor()

local function loadMap(file)
  io.input(file)
  local mapColumns = { "x", "y", "w", "h", "r", "g", "b" }
  local mapData = {}
  local i = 1
  while true do
    local line = io.read("*l")
    if line == nil then
      break
    end
    mapData[i] = {}
    local j = 1
    for match in string.gmatch(line, "([^,]*),") do
      mapData[i][mapColumns[j]] = tonumber(match)
      j = j + 1
    end
    i = i + 1
  end
  return mapData
end

local map = loadMap("assets/basic.map")

function love.load()
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode((gameDimensions * _G.SCALE_FACTOR):tuple())

  eventBus:subscribe("attackRequest", function(attackVectors)
    attackVectors.destination = camera:toWorldSpace(attackVectors.destination)
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
  camera = (hero.position - gameDimensions / 2):floor()

  for _, row in ipairs(map) do
    local point = camera:toObjectSpace(Vector2.new(row.x, row.y))
    local x = point.x * _G.SCALE_FACTOR
    local y = point.y * _G.SCALE_FACTOR
    local w = row.w * _G.SCALE_FACTOR
    local h = row.h * _G.SCALE_FACTOR
    love.graphics.setColor(row.r, row.g, row.b)
    love.graphics.rectangle("fill", x, y, w, h)
  end

  love.graphics.setColor(1, 1, 1)
  local x, y = (camera:toObjectSpace(hero.position):floor() * _G.SCALE_FACTOR):tuple()
  local w, h = (Vector2.new(8, 8) * _G.SCALE_FACTOR):tuple()
  love.graphics.rectangle("fill", x, y, w, h)

  love.graphics.setColor(1, 0, 0)
  if lastAttack then
    local x1, y1 = (camera:toObjectSpace(lastAttack.source):floor() * _G.SCALE_FACTOR):tuple()
    local x2, y2 = (camera:toObjectSpace(lastAttack.destination):floor() * _G.SCALE_FACTOR):tuple()
    love.graphics.line(x1, y1, x2, y2)
  end

  for projectile in projectileManager:iterate() do
    x, y = (camera:toObjectSpace(projectile.position):floor() * _G.SCALE_FACTOR):tuple()
    w, h = _G.SCALE_FACTOR, _G.SCALE_FACTOR
    love.graphics.rectangle("fill", x, y, w, h)
  end

  love.graphics.setColor(1, 1, 0)
  love.graphics.print(string.format("FPS: %d", love.timer.getFPS()))

end
