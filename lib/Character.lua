local ServiceLocator = require "lib.ServiceLocator"
local Vector2 = require "lib.Vector2"
local Weapon = require "lib.Weapon"

local eventBus = ServiceLocator:get("EventBus")

---@class Character
---@field private __kind string
---@field position Vector2
---@field weapon Weapon
---@field animation table
---@field animState string
---@field animMap table
local Character = { __kind = "Character" }
Character.__index = Character

---@return Character
function Character.new(position, weapon)
  local self = setmetatable({}, Character)
  self.position = position or Vector2.zero()
  self.weapon = weapon or Weapon.new(self)
  self.animation = {}
  self.animState = "stand_down"
  self.animMap = {
    stand_down = 1,
    walk_down = 2,
    stand_right = 3,
    walk_right = 4,
    stand_left = 5,
    walk_left = 6,
    stand_up = 7,
    walk_up = 8,
  }

  eventBus:subscribe("update", function(dt) self:onUpdate(dt) end)

  return self
end

function Character:onUpdate(dt)
  local speed = 60
  local move = Vector2.zero()
  if love.keyboard.isDown("w") then
    self.animState = "walk_up"
    move = move + Vector2.new(0, -1)
  end
  if love.keyboard.isDown("s") then
    self.animState = "walk_down"
    move = move + Vector2.new(0, 1)
  end
  if love.keyboard.isDown("a") then
    self.animState = "walk_left"
    move = move + Vector2.new(-1, 0)
  end
  if love.keyboard.isDown("d") then
    self.animState = "walk_right"
    move = move + Vector2.new(1, 0)
  end
  if string.find(self.animState, "walk") and not (love.keyboard.isDown("w") or love.keyboard.isDown("s") or love.keyboard.isDown("a") or love.keyboard.isDown("d")) then
    self.animState = "stand_down"
    self.animation.animId = self.animation.animId - 1
    self.animation.animIdx = 1
    self.animation.currentTime = 0
    self.animation.currentQuad = self.animation.quads[self.animation.animId][self.animation.animIdx]
  end
  if love.mouse.isDown(1) then
    eventBus:emit("attackRequest", {
      source = self.position,
      destination = Vector2.new(love.mouse.getPosition()) / _G.SCALE_FACTOR,
      self.weapon,
    })
  end
  self.position = self.position + move:unit() * (speed * dt)

  -- TODO refactor this
  if string.find(self.animState, "walk") then
    if self.animation.animId ~= self.animMap[self.animState] then
      self.animation.animId = self.animMap[self.animState]
      self.currentTime = 0
    end
    self.animation.currentTime = self.animation.currentTime + dt
    if self.animation.currentTime > self.animation.duration then
      self.animation.currentTime = 0
      self.animation.animIdx = self.animation.animIdx + 1
      if self.animation.animIdx > #self.animation.quads[self.animation.animId] then
        self.animation.animIdx = 1
      end
    end
    self.animation.currentQuad = self.animation.quads[self.animation.animId][self.animation.animIdx]
  end
end

return Character
