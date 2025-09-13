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
local sprites = {}
local scene = {}
local crtShader = {}

function love.load()
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode(gameDimensions.x * _G.SCALE_FACTOR, gameDimensions.y * _G.SCALE_FACTOR, { resizable = false, minwidth = 640, minheight = 480 })
  love.graphics.setDefaultFilter("nearest", "nearest")

  --scene = love.graphics.newCanvas(gameDimensions.x, gameDimensions.y, { dpiscale = 1 })
  --scene:setFilter("nearest", "nearest")

  --local shaderParams = {
  --  texSize = { gameDimensions.x, gameDimensions.y },
  --  outSize = { gameDimensions.x * _G.SCALE_FACTOR, gameDimensions.y * _G.SCALE_FACTOR },
  --  CURVATURE_X = 0.10,
  --  CURVATURE_Y = 0.15,
  --  MASK_BRIGHTNESS = 0.70,
  --  SCANLINE_WEIGHT = 0.60,
  --  SCANLINE_GAP_BRIGHTNESS = 0.12,
  --  BLOOM_FACTOR = 1.5,
  --  INPUT_GAMMA = 2.4,
  --  OUTPUT_GAMMA = 2.2,
  --  MASK_TYPE = 2.0,
  --  ENABLE_SCANLINES = 1.0,
  --  ENABLE_GAMMA = 1.0,
  --  ENABLE_FAKE_GAMMA = 1.0,
  --  ENABLE_CURVATURE = 0.0,
  --  ENABLE_SHARPER = 0.0,
  --  ENABLE_MULTISAMPLE = 1.0,
  --}
  --crtShader = love.graphics.newShader("crt.glsl")
  --for k, v in pairs(shaderParams) do
  --  crtShader:send(k, v)
  --end

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

  --love.graphics.setCanvas(scene)
  love.graphics.clear(0.05, 0.05, 0.06, 1)

  love.graphics.setColor(1, 1, 1, 1)
  Map:draw(-camera.x, -camera.y)

  love.graphics.setColor(1, 0, 0, 1)
  Map:box2d_draw(-camera.x, -camera.y)

  love.graphics.setColor(1, 1, 1, 1)
  local x, y = camera:toObjectSpace(hero.position):floor():tuple()
  local _, _, w, h = hero.animation.currentQuad:getViewport()
  love.graphics.draw(hero.animation.spriteSheet, hero.animation.currentQuad, x-(w/2), y-(h/2), 0)

  for projectile in projectileManager:iterate() do
    x, y = camera:toObjectSpace(projectile.position):floor():tuple()
    w, h = 1, 1
    love.graphics.rectangle("fill", x, y, w, h)
  end

  love.graphics.setColor(1, 0, 0, 1)
  love.graphics.print(string.format("FPS: %d", love.timer.getFPS()))
  love.graphics.print(string.format("VPF: %d", _G.VPF), 0, 12)
  love.graphics.print(string.format("x: %d y: %d", hero.position.x, hero.position.y), 0, 24)
  x, y = love.graphics.getDimensions()
  love.graphics.print(string.format("dim_x: %d dim_y: %d", x, y), 0, 36)

  --love.graphics.setCanvas()
  --love.graphics.setShader(crtShader)
  love.graphics.setColor(1, 1, 1, 1)
  --love.graphics.draw(scene, 0, 0, 0, _G.SCALE_FACTOR, _G.SCALE_FACTOR)
  --love.graphics.setShader()

  _G.VPF = 0
end
