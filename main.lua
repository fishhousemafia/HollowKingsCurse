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


require "core.EventBus"
require "systems.ActorManager"
require "systems.ProjectileManager"
local Map = require("core.Map")
local ServiceLocator = require "core.ServiceLocator"
local sti = require "core.sti"
local Vector2 = require "math.Vector2"
local eventBus = ServiceLocator:get("EventBus")
local actorManager = ServiceLocator:get("ActorManager")
local projectileManager = ServiceLocator:get("ProjectileManager")

_G.RUN_PROFILER = false
_G.SPRITES = nil ---@type love.ImageData[]
_G.GAME_DIMENSIONS = Vector2.new(320, 240)
_G.COLLISION_CATEGORIES = {
    BOUNDARY = 1,
    OBSTACLE = 2,
    FRIEND   = 3,
    ENEMY    = 4,
    FRIEND_P = 5,
    ENEMY_P  = 6,
    CAT_6    = 7,
    CAT_7    = 8,
    CAT_8    = 9,
    CAT_9    = 10,
    CAT_10   = 11,
    CAT_11   = 12,
    CAT_12   = 13,
    CAT_13   = 14,
    CAT_14   = 15,
    CAT_15   = 16,
}

local camera = Vector2.zero()
local map = {}
local hero = nil ---@type Actor
local scene = nil ---@type love.Canvas
local world = nil ---@type love.World

local function loadAssets(dir)
  local assets = {}

  local function walk(path, prefix)
    for _, item in ipairs(love.filesystem.getDirectoryItems(path)) do
      local subpath = path .. "/" .. item
      local info = love.filesystem.getInfo(subpath)
      if info and info.type == "directory" then
        walk(subpath, prefix and (prefix .. "/" .. item) or item)
      elseif info and info.type == "file" then
        if item:lower():match("%.png$") then
          local base = item:match("([^/]+)%.png$")
          local key = base

          if assets[key] then
            local rel = (prefix and (prefix .. "/" .. base) or base):gsub("/", "_")
            key = rel
          end

          assets[key] = love.image.newImageData(subpath)
        end
      end
    end
  end

  walk(dir, nil)
  return assets
end
_G.SPRITES = loadAssets("sprites")

function love.load()
  if _G.RUN_PROFILER then
    love.profiler = require("profile")
    love.profiler.start()
  end

  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / _G.GAME_DIMENSIONS):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode(_G.GAME_DIMENSIONS.x * _G.SCALE_FACTOR, _G.GAME_DIMENSIONS.y * _G.SCALE_FACTOR, { resizable = false, minwidth = 640, minheight = 480 })
  love.graphics.setDefaultFilter("nearest", "nearest")
  scene = love.graphics.newCanvas(_G.GAME_DIMENSIONS.x, _G.GAME_DIMENSIONS.y, { dpiscale = 1 })

  love.physics.setMeter(8)
  map = Map.new("data/maps/default.lua")
  world = love.physics.newWorld(0, 0)
  map:initPhysics(world)

  world:setCallbacks(
    function(fixture1, fixture2, contact)
      eventBus:emit("beginContact", {
        fixture1 = fixture1,
        fixture2 = fixture2,
        contact = contact,
      })
    end,
    function(fixture1, fixture2, contact)
      eventBus:emit("endContact", {
        fixture1 = fixture1,
        fixture2 = fixture2,
        contact = contact,
      })
    end,
    function(fixture1, fixture2, contact)
      eventBus:emit("preSolve", {
        fixture1 = fixture1,
        fixture2 = fixture2,
        contact = contact,
      })
    end,
    function(fixture1, fixture2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
      eventBus:emit("postSolve", {
        fixture1 = fixture1,
        fixture2 = fixture2,
        contact = contact,
        normal_impulse1 = normal_impulse1,
        tangent_impulse1 = tangent_impulse1,
        normal_impulse2 = normal_impulse2,
        tangent_impulse2 = tangent_impulse2,
      })
    end
  )

  local makeHero = require "blueprints.actors.hero"
  hero = makeHero()
  hero:enable(world, _G.GAME_DIMENSIONS, true)

  eventBus:subscribe("attackRequest", function(attackVectors)
    attackVectors.destination = camera:toWorldSpace(attackVectors.destination)
    hero.weapon:attack(attackVectors.source, attackVectors.destination)
  end)

  eventBus:subscribe("projectileFired", function(projectile)
    projectileManager:add(projectile)
  end)

  eventBus:subscribe("error", function(eventName, trace)
    print(eventName)
    print(trace)
  end)
end

local hudEnabled = true
local profilerPause = false
function love.keypressed(key)
  if key == "q" then
    love.event.quit()
  end
  if key == "h" then
    hudEnabled = not hudEnabled
  end
  if key == "p" then
    profilerPause = not profilerPause
  end
end

local tick = 1/120
local maxSteps = 8
local maxAccumulator = tick * maxSteps
local accumulator = 0
local spawnTimer = 0
love.frame = 0

function love.update(dt)
  love.frame = love.frame + 1
  if love.frame % 100 == 0 and not profilerPause and _G.RUN_PROFILER then
    love.profiler.stop()
    love.report = love.profiler.report(20)
    love.profiler.reset()
    love.profiler.start()
  end

  accumulator = math.min(accumulator + dt, maxAccumulator)
  local steps = 0
  while accumulator >= tick and steps < maxSteps do
    world:update(tick)
    actorManager:update(tick)
    projectileManager:update(tick)
    steps = steps + 1
    accumulator = accumulator - tick
  end

  spawnTimer = spawnTimer - dt
  if spawnTimer <= 0 then
    spawnTimer = 1
    local makeEnemy = require "blueprints.actors.enemy"
    local enemy = makeEnemy()
    local position = Vector2.new(love.math.random(640), love.math.random(480))
    enemy:enable(world, position)
  end
end

local function drawGame()
  local heroPosition = Vector2.fromBody(hero.body)
  camera = (heroPosition - (_G.GAME_DIMENSIONS / 2)):floor()

  love.graphics.setColor(1, 1, 1, 1)
  map:draw(-camera.x, -camera.y)

  for _, actor in pairs(actorManager:getEnabled()) do
    love.graphics.setColor(1, 1, 1, 1)
    local position = Vector2.fromBody(actor.body)
    local x, y = camera:toObjectSpace(position):floor():tuple()
    local _, _, w, h = actor.animation.currentQuad:getViewport()
    love.graphics.draw(actor.animation.spriteSheet, actor.animation.currentQuad, x-(w/2), y-(h/2), 0)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", x-(w/2)-1, y+(h/2)+1, w+2, 3)
    local pct = actor.health / actor.maxHealth
    local len = pct * w
    local r = 1 - pct
    local g = pct
    local bright = math.min(r, g)
    love.graphics.setColor(r+bright, g+bright, 0, 1)
    love.graphics.rectangle("fill", x-(w/2), y+(h/2)+2, len, 1)
  end

  love.graphics.setColor(1, 1, 1, 1)
  for _, projectile in pairs(projectileManager:getAll()) do
    local x, y = camera:toObjectSpace(Vector2.fromBody(projectile.body)):floor():tuple()
    local w, h = 1, 1
    love.graphics.rectangle("fill", x, y, w, h)
  end

  --love.graphics.setColor(1, 0, 0, 1)
  --for _, body in pairs(world:getBodies()) do
  --  for _, fixture in pairs(body:getFixtures()) do
  --    local x1, y1, x2, y2 = fixture:getBoundingBox()
  --    local w, h = x2 - x1, y2 - y1
  --    local point = camera:toObjectSpace(Vector2.new(x1, y1))
  --    love.graphics.rectangle("line", point.x, point.y, w, h)
  --  end
  --end

  love.graphics.setColor(1, 1, 1, 1)
end

local function drawHud()
  -- minimap
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 252, 2, 66, 50)
  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.rectangle("fill", 253, 3, 64, 48)

  -- vitals
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 2, 2, 82, 6)
  local pct = hero.health / hero.maxHealth
  local len = pct * 80
  local r = 1 - pct
  local g = pct
  local bright = math.min(r, g)
  love.graphics.setColor(r+bright, g+bright, 0, 1)
  love.graphics.rectangle("fill", 3, 3, len, 4)

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("fill", 2, 10, 82, 6)
  love.graphics.setColor(0, 0, 1, 1)
  love.graphics.rectangle("fill", 3, 11, 80, 4)

  -- inventory
  for i=0, 9 do
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 101+(i*12), 228, 10, 10)

    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("fill", 102+(i*12), 229, 8, 8)
  end
end

local mono = love.graphics.newFont("fonts/RobotoMono-Regular.ttf")
function love.draw()
  if hero.isEnabled then
    love.graphics.setCanvas(scene)
    love.graphics.clear(0, 0, 0, 1)
    drawGame()
    drawHud()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(scene, 0, 0, 0, _G.SCALE_FACTOR, _G.SCALE_FACTOR)
  end

  if hudEnabled then
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, 820, 420)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(("FPS: %d"):format(love.timer.getFPS()), 1, 1)
    love.graphics.print(love.report or "Please wait...", mono, 1, 13)
  end
end
