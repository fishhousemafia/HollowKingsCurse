local Vector2 = require("library/Vector2")

---@class Projectile
---@field private __index Projectile
---@field private kind string
---@field parent Weapon
---@field activate function
---@field evaluate function
---@field active boolean
---@field lifetime number
---@field source Vector2
---@field position Vector2
---@field destination Vector2
local Projectile = {
  kind = "Projectile"
}
Projectile.__index = Projectile

local function dActivate(self, source, destination)
  self.active = true
  self.lifetime = 2
  self.source = source
  self.position = source
  self.destination = destination

  local angle = self.source:angle(destination, true)
  self.delta = Vector2.new(math.cos(angle), math.sin(angle))
end

local function dEvaluate(self, dt)
  self.lifetime = self.lifetime - dt
  if self.lifetime <= 0 then
    self.active = false
    return
  end

  local speed = 80
  self.position = self.position + (self.delta * speed * dt)
end

---@return Projectile
function Projectile.new(parent, activate, evaluate)
  local self = setmetatable({}, Projectile)
  self.parent = parent
  self.activate = activate or dActivate
  self.evaluate = evaluate or dEvaluate
  self.active = false
  self.lifetime = 0
  self.source = Vector2.zero()
  self.position = Vector2.zero()
  self.destination = Vector2.zero()
  return self
end

---@return Projectile
function Projectile:clone()
  return Projectile.new(self.parent, self.activate, self.evaluate)
end

function Projectile:reset()
  self.parent:returnProjectile(self)
end

return Projectile
