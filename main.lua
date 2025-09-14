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
local ServiceLocator = require "core.ServiceLocator"
local sti = require "core.sti"
local Vector2 = require "math.Vector2"
local eventBus = ServiceLocator:get("EventBus")
local actorManager = ServiceLocator:get("ActorManager")
local projectileManager = ServiceLocator:get("ProjectileManager")

_G.SPRITES = nil ---@type love.ImageData[]

local gameDimensions = Vector2.new(320, 240)
local camera = Vector2.zero()
local map = {}
local hero = nil ---@type Actor
local enemy = nil ---@type Actor
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

function love.load()
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode(gameDimensions.x * _G.SCALE_FACTOR, gameDimensions.y * _G.SCALE_FACTOR, { resizable = false, minwidth = 640, minheight = 480 })
  love.graphics.setDefaultFilter("nearest", "nearest")
  scene = love.graphics.newCanvas(gameDimensions.x, gameDimensions.y, { dpiscale = 1 })

  love.physics.setMeter(8)
  map = sti("maps/default/default.lua", { "box2d" })
  world = love.physics.newWorld(0, 0)
  map:box2d_init(world)

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

  hero = require "blueprints.actors.hero"
  hero:enable(world, gameDimensions, true)
  enemy = require "blueprints.actors.enemy"
  enemy:enable(world, gameDimensions / 2)

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

function love.keypressed(key)
  if key == "q" then
    love.event.quit()
  end
end

function love.update(dt)
  world:update(dt)
  actorManager:update(dt)
  projectileManager:update(dt)
  eventBus:emit("update", dt)
end

local function drawGame()
  local heroPosition = Vector2.fromBody(hero.body)
  camera = (heroPosition - (gameDimensions / 2)):floor()

  love.graphics.setColor(1, 1, 1, 1)
  map:draw(-camera.x, -camera.y)

  love.graphics.setColor(1, 0, 0, 1)
  map:box2d_draw(-camera.x, -camera.y)

  love.graphics.setColor(1, 1, 1, 1)
  for _, actor in pairs(actorManager:getEnabled()) do
    local position = Vector2.fromBody(actor.body)
    local x, y = camera:toObjectSpace(position):floor():tuple()
    local _, _, w, h = actor.animation.currentQuad:getViewport()
    love.graphics.draw(actor.animation.spriteSheet, actor.animation.currentQuad, x-(w/2), y-(h/2), 0)
  end

  for _, projectile in pairs(projectileManager:getAll()) do
    local x, y = camera:toObjectSpace(Vector2.fromBody(projectile.body)):floor():tuple()
    local w, h = 1, 1
    love.graphics.rectangle("fill", x, y, w, h)
  end
end

function love.draw()
  if hero.isEnabled then
    love.graphics.setCanvas(scene)
    love.graphics.clear(0, 0, 0, 1)
    drawGame()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.draw(scene, 0, 0, 0, _G.SCALE_FACTOR, _G.SCALE_FACTOR)
  end

  love.graphics.print(("FPS: %d"):format(love.timer.getFPS()), 1, 1)
end
