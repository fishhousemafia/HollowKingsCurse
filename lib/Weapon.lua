local ServiceLocator = require "lib.ServiceLocator"
local Projectile = require "lib.Projectile"

local eventBus = ServiceLocator:get("EventBus")

---@class Weapon
---@field private __kind string
---@field parent Character
---@field projectile Projectile
---@field pool Projectile[]
local Weapon = { __kind = "Weapon" }
Weapon.__index = Weapon

---@return Weapon
function Weapon.new(parent, projectile)
  local self = setmetatable({}, Weapon)
  self.parent = parent
  self.projectile = projectile or Projectile.new(self)
  return self
end

function Weapon:attack(source, destination)
  local projectile = self.projectile:clone()
  projectile:activate(source, destination)
  eventBus:emit("projectileFired", projectile)
end

return Weapon
