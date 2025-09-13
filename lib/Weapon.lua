local ServiceLocator = require "lib.ServiceLocator"

local eventBus = ServiceLocator:get("EventBus")

---@class Weapon
---@field private __kind string
---@field projectile Projectile
---@field pool Projectile[]
local Weapon = { __kind = "Weapon" }
Weapon.__index = Weapon

---@return Weapon
function Weapon.new(projectile)
  local self = setmetatable({}, Weapon)
  self.projectile = projectile
  return self
end

function Weapon:attack(source, destination)
  local projectile = self.projectile:clone()
  projectile:activate(source, destination)
  eventBus:emit("projectileFired", projectile)
end

return Weapon
