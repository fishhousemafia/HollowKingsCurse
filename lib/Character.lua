local ServiceLocator = require "lib.ServiceLocator"
local Vector2 = require "lib.Vector2"
local Weapon = require "lib.Weapon"

local eventBus = ServiceLocator:get("EventBus")

---@class Character
---@field private __index Character
---@field private kind string
---@field position Vector2
---@field weapon Weapon
local Character = { kind = "Character" }
Character.__index = Character

---@return Character
function Character.new(position, weapon)
  local self = setmetatable({}, Character)
  self.position = position or Vector2.zero()
  self.weapon = weapon or Weapon.new(self)

  eventBus:subscribe("update", function(dt) self:onUpdate(dt) end)

  return self
end

function Character:onUpdate(dt)
  local speed = 60
  local move = Vector2.zero()
  if love.keyboard.isDown("w") then
    move = move + Vector2.new(0, -1)
  end
  if love.keyboard.isDown("a") then
    move = move + Vector2.new(-1, 0)
  end
  if love.keyboard.isDown("s") then
    move = move + Vector2.new(0, 1)
  end
  if love.keyboard.isDown("d") then
    move = move + Vector2.new(1, 0)
  end
  if love.mouse.isDown(1) then
    eventBus:emit("attackRequest", {
      source = self.position,
      destination = Vector2.new(love.mouse.getPosition()) / _G.SCALE_FACTOR,
      self.weapon,
    })
  end

  self.position = self.position + move:unit() * (speed * dt)
end

return Character
