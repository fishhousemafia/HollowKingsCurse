local Vector2 = require "math.Vector2"
local Projectile = require "objects.Projectile"

local function activate(self, source, destination)
  local angle      = source:angle(destination, true)
  self.active      = true
  self.lifetime    = 2
  self.source      = source
  self.position    = source
  self.destination = destination
  self.delta       = Vector2.new(math.cos(angle), math.sin(angle))
  self.speed = -100
end

local function evaluate(self, dt)
  self.lifetime     = self.lifetime - dt
  if self.lifetime <= 0 then self.active = false; return end
  self.position     = self.position + (self.delta * self.speed * dt)
  self.speed = self.speed + 5
end

local function collide()
end

return Projectile.new(activate, evaluate, collide)

