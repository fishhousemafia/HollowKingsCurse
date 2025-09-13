local Vector2 = require "lib.Vector2"

---@class Projectile
---@field private __kind string
---@field activate fun(self: Projectile, source: Vector2, destination: Vector2)
---@field evaluate fun(self: Projectile, dt: number)
---@field onCollide fun(self: Projectile, target: any) | nil
---@field active boolean
---@field lifetime number
---@field source Vector2
---@field position Vector2
---@field destination Vector2
---@field delta Vector2
local Projectile = { __kind = "Projectile" }
Projectile.__index = Projectile

local function dActivate(self, source, destination)
  local angle      = source:angle(destination, true)
  self.active      = true
  self.lifetime    = 2
  self.source      = source
  self.position    = source
  self.destination = destination
  self.delta       = Vector2.new(math.cos(angle), math.sin(angle))
end

local function dEvaluate(self, dt)
  local speed       = 80
  self.lifetime     = self.lifetime - dt
  if self.lifetime <= 0 then self.active = false; return end
  self.position     = self.position + (self.delta * speed * dt)
end

---@return Projectile
function Projectile.new(activate, evaluate, onCollide)
  local self = setmetatable({}, Projectile)
  self.activate  = activate or dActivate
  self.evaluate  = evaluate or dEvaluate
  self.onCollide = onCollide
  self.active    = false
  self.lifetime  = 0
  self.source    = Vector2.zero()
  self.position  = Vector2.zero()
  self.destination = Vector2.zero()
  self.delta     = Vector2.zero()
  return self
end

function Projectile:clone()
  return Projectile.new(self.activate, self.evaluate, self.onCollide)
end

function Projectile:reset()
  self.active = false
  self.lifetime = 0
end

return Projectile

