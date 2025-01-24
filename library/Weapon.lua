local ServiceLocator = require("library/ServiceLocator")
local Projectile = require("library/Projectile")

local eventBus = ServiceLocator:get("EventBus")

---@class Weapon
---@field private __index Weapon
---@field private kind string
---@field parent Character
---@field projectile Projectile
---@field pool Projectile[]
local Weapon = { kind = "Weapon" }
Weapon.__index = Weapon

---@return Weapon
function Weapon.new(parent, projectile)
  local self = setmetatable({}, Weapon)
  self.parent = parent
  self.projectile = projectile or Projectile.new(self)
  self.pool = {}
  return self
end

function Weapon:attack(source, destination)
  if #self.pool == 0 then
    table.insert(self.pool, self.projectile:clone())
  end

  local projectile = table.remove(self.pool)
  projectile:activate(source, destination)
  eventBus:emit("projectileFired", projectile)
end

function Weapon:returnProjectile(projectile)
  table.insert(self.pool, projectile)
end

return Weapon
