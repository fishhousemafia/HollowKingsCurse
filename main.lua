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

local EventBus = require "lib.EventBus"
local ProjectileManager = require "lib.ProjectileManager"
local ServiceLocator = require "lib.ServiceLocator"

local eventBus = ServiceLocator:register("EventBus", EventBus.new())
local projectileManager = ServiceLocator:register("ProjectileManager", ProjectileManager.new())

local Character = require "lib.Character"
local Vector2 = require "lib.Vector2"
local Animation = require "lib.Animation"

local sti = require "lib.sti"

_G.SCALE_FACTOR = 1
_G.VPF = 0

local gameDimensions = Vector2.new(320, 240)
local hero = Character.new(gameDimensions / 2)
local camera = Vector2.zero()

local mapData = require "assets.map"
local mapTiles = love.graphics.newImage("assets/sprites/map_tiles.png")
local sprites = {}

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode((gameDimensions * _G.SCALE_FACTOR):tuple())

  eventBus:subscribe("attackRequest", function(attackVectors)
    attackVectors.destination = camera:toWorldSpace(attackVectors.destination)
    hero.weapon:attack(attackVectors.source, attackVectors.destination)
  end)

  eventBus:subscribe("projectileFired", function(projectile)
    projectileManager:add(projectile)
  end)

  local function loadAssets(directory)
    local assetFiles = {}
    local i = 1
    local pfile = nil
    while pfile == nil do
      pfile = io.popen('find "' .. directory .. '" -name *.png')
    end
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
  sprites = loadAssets("assets/sprites")
  mapTiles = love.graphics.newImage(sprites["map_tiles"])

  hero.animation = Animation.new(sprites["hero"], 8, 8, 0.333)

  love.physics.setMeter(8 * _G.SCALE_FACTOR)
  Map = sti("assets/maps/default/default.lua", { "box2d" })
  World = love.physics.newWorld(0, 0)
  Map:box2d_init(World)
end

function love.keypressed(key)
  if key == "q" then
    love.event.quit()
  end
end

function love.update(dt)
  eventBus:emit("update", dt)
  projectileManager:evaluate(dt)
  Map:update(dt)
end

function love.draw()
  camera = (hero.position - gameDimensions / 2):floor()

  --for world_y, row in ipairs(mapData) do
  --  for world_x, cell in ipairs(row) do
  --    local w = 8
  --    local h = 8
  --    local x = (8 * world_x) - 8
  --    local y = (8 * world_y) - 8
  --    if x + w < camera.x or y + h < camera.y or
  --      x > camera.x + gameDimensions.x or y > camera.y + gameDimensions.y then
  --      goto continue
  --    end
  --    local point = camera:toObjectSpace(Vector2.new(x, y))
  --    local img_x, img_y = (cell[1] * 8) - 8, (cell[2] * 8) - 8
  --    local quad = love.graphics.newQuad(img_x, img_y, 8, 8, sprites["map_tiles"]:getDimensions())
  --    x = point.x * _G.SCALE_FACTOR
  --    y = point.y * _G.SCALE_FACTOR
  --    love.graphics.draw(mapTiles, quad, x, y, 0, _G.SCALE_FACTOR, _G.SCALE_FACTOR)
  --    ::continue::
  --  end
  --end


  love.graphics.setColor(1, 1, 1)
  Map:draw(-camera.x, -camera.y, _G.SCALE_FACTOR, _G.SCALE_FACTOR)

  love.graphics.setColor(1, 0, 0)
  Map:box2d_draw(-camera.x, -camera.y, _G.SCALE_FACTOR, _G.SCALE_FACTOR)

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
