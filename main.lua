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

require "lib.EventBus"
require "lib.ProjectileManager"
local ServiceLocator = require "lib.ServiceLocator"
local eventBus = ServiceLocator:get("EventBus")
local projectileManager = ServiceLocator:get("ProjectileManager")

local Character = require "lib.Character"
local Weapon = require "lib.Weapon"
local Vector2 = require "lib.Vector2"
local Animation = require "lib.Animation"
local Projectile = require "lib.Projectile"

local sti = require "lib.sti"

local gameDimensions = Vector2.new(320, 240)
local camera = Vector2.zero()
local map = {}
local hero = nil ---@type Character
local sprites = nil ---@type love.ImageData[]
local scene = nil ---@type love.Canvas
local world = nil ---@type love.World

function love.load()
  local desktopDimensions = Vector2.new(love.window.getDesktopDimensions(1))
  local scaled = (desktopDimensions / gameDimensions):floor()
  _G.SCALE_FACTOR = math.min(scaled:tuple()) - 1
  love.window.setMode(gameDimensions.x * _G.SCALE_FACTOR, gameDimensions.y * _G.SCALE_FACTOR, { resizable = false, minwidth = 640, minheight = 480 })
  love.graphics.setDefaultFilter("nearest", "nearest")
  scene = love.graphics.newCanvas(gameDimensions.x, gameDimensions.y, { dpiscale = 1 })

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
  sprites = loadAssets("assets/sprites")

  love.physics.setMeter(8)
  map = sti("assets/maps/default/default.lua", { "box2d" })
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

  local hero_animationDict = {
    stand_down =  { id = 1, duration = 0 },
    walk_down =   { id = 2, duration = 0.333 },
    stand_right = { id = 3, duration = 0 },
    walk_right =  { id = 4, duration = 0.333 },
    stand_left =  { id = 5, duration = 0 },
    walk_left =   { id = 6, duration = 0.333 },
    stand_up =    { id = 7, duration = 0 },
    walk_up =     { id = 8, duration = 0.333 },
  }
  local hero_animation = Animation.new(sprites["hero"], 8, 8, hero_animationDict, "stand_down")

  local hero_bullet = Projectile.new(nil, nil, function(self, target)
    -- onCollide
  end)
  local hero_weapon = Weapon.new(hero_bullet, 0.1, nil)

  local hero_onUpdate = function(character, dt)
    local speed = 4000
    local move = Vector2.zero()
    if love.keyboard.isDown("w") then
      character.animation:animate("walk_up", dt)
      move = move + Vector2.new(0, -1)
    end
    if love.keyboard.isDown("s") then
      character.animation:animate("walk_down", dt)
      move = move + Vector2.new(0, 1)
    end
    if love.keyboard.isDown("a") then
      character.animation:animate("walk_left", dt)
      move = move + Vector2.new(-1, 0)
    end
    if love.keyboard.isDown("d") then
      character.animation:animate("walk_right", dt)
      move = move + Vector2.new(1, 0)
    end
    if string.find(character.animation.currentAnimation, "walk") and not (love.keyboard.isDown("w") or love.keyboard.isDown("s") or love.keyboard.isDown("a") or love.keyboard.isDown("d")) then
      local standAnimation = character.animation.currentAnimation:gsub("^walk", "stand")
      character.animation:animate(standAnimation, dt)
    end

    local velocity = move:unit() * (speed * dt)
    character.body:setLinearVelocity(velocity:tuple())

    character.weapon:update(dt)
    if love.mouse.isDown(1) then
      eventBus:emit("attackRequest", {
        source = Vector2.fromBody(character.body),
        destination = Vector2.new(love.mouse.getPosition()) / _G.SCALE_FACTOR,
        weapon = character.weapon,
      })
    end
  end
  hero = Character.new(hero_animation, hero_weapon, hero_onUpdate)
  hero:enable(world, gameDimensions)

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
  projectileManager:update(world, dt)
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
  local x, y = camera:toObjectSpace(heroPosition):floor():tuple()
  local _, _, w, h = hero.animation.currentQuad:getViewport()
  love.graphics.draw(hero.animation.spriteSheet, hero.animation.currentQuad, x-(w/2), y-(h/2), 0)

  for _, projectile in pairs(projectileManager:getAll()) do
    x, y = camera:toObjectSpace(projectile.position):floor():tuple()
    w, h = 1, 1
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
end
