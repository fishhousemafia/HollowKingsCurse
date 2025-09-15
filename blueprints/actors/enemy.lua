local Animation = require "graphics.Animation"
local Vector2 = require "math.Vector2"
local Character = require "objects.Actor"

local function animationFromVec2(v)
  local cardinals = {}
  cardinals[Vector2.new(1, 0)] = "walk_right"
  cardinals[Vector2.new(-1, 0)] = "walk_left"
  cardinals[Vector2.new(0, 1)] = "walk_down"
  cardinals[Vector2.new(0, -1)] = "walk_up"

  local bestDot, best = -math.huge, nil
  for dir, animation in pairs(cardinals) do
    local d = v:dot(dir)
    if d > bestDot then
      bestDot, best = d, animation
    end
  end

  return best
end

local function onUpdate(character, dt)
  character.state.time = character.state.time - dt
  if character.state.time <= 0 then
    character.state.time = love.math.random(5000) / 1000
    character.state.direction = Vector2.new(love.math.random(-1000, 1000)/1000, love.math.random(-1000, 1000)/1000):unit()
    if character.state.direction == Vector2.zero() then
      character.state.animation = character.animation.currentAnimation:gsub("^walk", "stand")
    else
      character.state.animation = animationFromVec2(character.state.direction)
    end
  end
  character.animation:animate(character.state.animation, dt)

  local speed = 20
  local velocity = character.state.direction * speed
  character.body:setLinearVelocity(velocity:tuple())
end

local humanoid_4dir = require "data.animations.humanoid_4dir"
return function()
  local animation = Animation.new(_G.SPRITES["hero"], 8, 8, humanoid_4dir, "stand_down")
  local makeWeapon = require "blueprints.weapons.default"
  local out = Character.new(animation, makeWeapon(), onUpdate)
  out.state = {
    time = 0,
    direction = Vector2.zero(),
    animation = "stand_down",
  }
  return out
end
