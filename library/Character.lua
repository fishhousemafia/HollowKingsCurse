local Weapon = require("library/Weapon")
local Vector2 = require("library/Vector2")

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
  return self
end

---@param moveVector Vector2
function Character:move(moveVector)
  self.position = self.position + moveVector
end

return Character
