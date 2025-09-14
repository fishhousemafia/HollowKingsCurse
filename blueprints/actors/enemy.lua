local Animation = require "graphics.Animation"
local Vector2 = require "math.Vector2"
local Character = require "objects.Actor"

local state = {
  time = 0,
  direction = Vector2.zero(),
  animation = "stand_down",
}

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
  state.time = state.time - dt
  if state.time <= 0 then
    state.time = love.math.random(1)
    state.direction = Vector2.new(love.math.random(-1, 1), love.math.random(-1, 1)):unit()
    if state.direction == Vector2.zero() then
      state.animation = character.animation.currentAnimation:gsub("^walk", "stand")
    else
      state.animation = animationFromVec2(state.direction)
    end
  end

  local speed = 2000
  local velocity = state.direction * (speed * dt)
  character.body:setLinearVelocity(velocity:tuple())
  character.animation:animate(state.animation, dt)
end

local humanoid_4dir = require "blueprints.animations.humanoid_4dir"
local animation = Animation.new(_G.SPRITES["hero"], 8, 8, humanoid_4dir, "stand_down")
local weapon = require "blueprints.weapons.default"
return Character.new(animation, weapon, onUpdate)
