local ServiceLocator = require "core.ServiceLocator"
local Animation = require "graphics.Animation"
local Vector2 = require "math.Vector2"
local Character = require "objects.Actor"
local eventBus = ServiceLocator:get("EventBus")

local onUpdate = function(character, dt)
  local speed = 80
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

  local velocity = move:unit() * speed
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

local humanoid_4dir = require "data.animations.humanoid_4dir"
local animation = Animation.new(_G.SPRITES["hero"], 8, 8, humanoid_4dir, "stand_down")
local makeWeapon = require "blueprints.weapons.default"
return function()
  return Character.new(animation, makeWeapon(), onUpdate)
end

