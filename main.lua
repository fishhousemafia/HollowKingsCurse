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
_G.VPF = 0

local eventBus = ServiceLocator:register(EventBus)
local projectileManager = ServiceLocator:register(ProjectileManager)
local gameDimensions = Vector2.new(320, 240)
local hero = Character.new(gameDimensions / 2)
local lastAttack = nil
local camera = Vector2.zero()

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
  love.graphics.setDefaultFilter("nearest", "nearest")
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

  local function loadAssets(directory)
    local assetFiles = {}
    local i = 1
    local pfile = io.popen('find "' .. directory .. '" -name *.png')
    for filename in pfile:lines() do
      assetFiles[i] = filename
      i = i + 1
    end
    pfile:close()

    local assets = {}
    for _, filename in ipairs(assetFiles) do
      local start = string.find(filename, "/[^/]*$")
      local stop = string.find(filename, ".png$")
      assets[string.sub(filename, start + 1, stop - 1)] = love.image.newImageData(filename)
    end
    return assets
  end
  local sprites = loadAssets("assets/sprites")

  -- TODO create an Animation class
  local function newAnimation(imageData, width, height, duration)
    local animation = {}
    animation.spriteSheet = love.graphics.newImage(imageData)
    animation.quads = {};
    animation.duration = duration
    animation.currentTime = 0
    animation.animIdx = 1
    animation.animId = 1

    for y = 0, imageData:getHeight() - height, height do
      local row = {}
      for x = 0, imageData:getWidth() - width, width do
        local isEmpty = true
        for yy = y, height + y - 1 do
          for xx = x, width + x - 1 do
            local r, g, b, a = imageData:getPixel(xx, yy)
            if (r ~= 0 or g ~= 0 or b ~= 0) and a > 0 then
              isEmpty = false
            end
          end
        end
        if not isEmpty then
          table.insert(row, love.graphics.newQuad(x, y, width, height, imageData:getDimensions()))
        end
      end
      table.insert(animation.quads, row)
    end
    animation.currentQuad = animation.quads[1][1]

    return animation
  end
  hero.animation = newAnimation(sprites["hero"], 8, 8, 0.333)
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
    if row.x + row.w < camera.x or row.y + row.h < camera.y or
      row.x > camera.x + gameDimensions.x or row.y > camera.y + gameDimensions.y then
      goto continue
    end
    local point = camera:toObjectSpace(Vector2.new(row.x, row.y))
    local x = point.x * _G.SCALE_FACTOR
    local y = point.y * _G.SCALE_FACTOR
    local w = row.w * _G.SCALE_FACTOR
    local h = row.h * _G.SCALE_FACTOR
    love.graphics.setColor(row.r, row.g, row.b)
    love.graphics.rectangle("fill", x, y, w, h)
    ::continue::
  end

  love.graphics.setColor(1, 1, 1)
  local x, y = (camera:toObjectSpace(hero.position):floor() * _G.SCALE_FACTOR):tuple()
  local _, _, w, h = hero.animation.currentQuad:getViewport()
  w, h = w * _G.SCALE_FACTOR, h * _G.SCALE_FACTOR
  love.graphics.draw(hero.animation.spriteSheet, hero.animation.currentQuad, x-(w/2), y-(h/2), 0, _G.SCALE_FACTOR, _G.SCALE_FACTOR)

  for projectile in projectileManager:iterate() do
    x, y = (camera:toObjectSpace(projectile.position):floor() * _G.SCALE_FACTOR):tuple()
    w, h = _G.SCALE_FACTOR, _G.SCALE_FACTOR
    love.graphics.rectangle("fill", x, y, w, h)
  end

  love.graphics.setColor(1, 1, 0)
  love.graphics.print(string.format("FPS: %d", love.timer.getFPS()))
  love.graphics.print(string.format("VPF: %d", _G.VPF), 0, 12)
  love.graphics.print(string.format("x: %d y: %d", hero.position.x, hero.position.y), 0, 24)
  _G.VPF = 0
end
