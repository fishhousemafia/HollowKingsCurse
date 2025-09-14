local ServiceLocator = require "core.ServiceLocator"
local eventBus = ServiceLocator:get("EventBus")
local ProjectileManager = ServiceLocator:get("ProjectileManager")

---@class Weapon
---@field private __kind string
---@field blueprint Projectile
---@field cooldown number
---@field _timer number
---@field pattern fun(self: Weapon, source: any, destination: any): (Projectile[])
---@field world love.World
---@field friendly boolean
local Weapon = { __kind = "Weapon" }
Weapon.__index = Weapon

local function dPattern(self, source, destination)
  self.blueprint.source = source
  self.blueprint.destination = destination
  return { self.blueprint }
end

---@param blueprint Projectile
---@param cooldown number|nil
---@param pattern fun(self: Weapon, source:any, destination:any):(Projectile[])|nil
function Weapon.new(blueprint, cooldown, pattern)
  local self = setmetatable({}, Weapon)
  self.blueprint = blueprint
  self.cooldown  = cooldown or 0
  self._timer    = 0
  self.pattern   = pattern or dPattern
  self.friendly  = false

  return self
end

function Weapon:update(dt)
  if self._timer > 0 then
    self._timer = math.max(0, self._timer - dt)
  end
end

function Weapon:ready()
  if self._timer == 0 and self.world ~= nil then
    return true
  end
  return false
end

function Weapon:attack(source, destination)
  if not self:ready() then return false end
  self._timer = self.cooldown

  local blueprints = self.pattern(self, source, destination)
  if not blueprints or #blueprints == 0 then
    eventBus:emit("weapon:dryfire", self)
    return false
  end

  for i = 1, #blueprints do
    local bp = blueprints[i]
    local live = ProjectileManager:spawn(bp, self.world, self.friendly)
    eventBus:emit("projectile:spawn", live, self)
  end
  eventBus:emit("weapon:attack", self, #blueprints)
  return true
end

return Weapon

