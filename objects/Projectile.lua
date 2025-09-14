local Vector2 = require "math.Vector2"

---@class Projectile
---@field private __kind string
---@field activate fun(self: Projectile, source: Vector2, destination: Vector2, collisionWorld: love.World, friendly: boolean)
---@field evaluate fun(self: Projectile, dt: number)
---@field onCollide fun(self: Projectile, target: any) | nil
---@field active boolean
---@field lifetime number
---@field source Vector2
---@field position Vector2
---@field destination Vector2
---@field delta Vector2
---@field body love.Body
---@field fixture love.Fixture
local Projectile = { __kind = "Projectile" }
Projectile.__index = Projectile

local function dActivate(self, source, destination, collisionWorld, friendly)
  local speed      = 100
  local angle      = source:angle(destination, true)
  local angleVector = Vector2.new(math.cos(angle), math.sin(angle))
  local velocity    = angleVector * speed
  self.active      = true
  self.lifetime    = 2
  self.source      = source
  self.position    = source
  self.destination = destination
  self.body        = love.physics.newBody(collisionWorld, source.x, source.y, "dynamic")
  local shape      = love.physics.newRectangleShape(1, 1)
  self.fixture     = love.physics.newFixture(self.body, shape, 1)
  if friendly then
    self.fixture:setCategory(_G.COLLISION_CATEGORIES.FRIEND_P)
    self.fixture:setMask(_G.COLLISION_CATEGORIES.FRIEND, _G.COLLISION_CATEGORIES.FRIEND_P)
  else
    self.fixture:setCategory(_G.COLLISION_CATEGORIES.ENEMY_P)
    self.fixture:setMask(_G.COLLISION_CATEGORIES.ENEMY, _G.COLLISION_CATEGORIES.ENEMY_P)
  end
  self.body:setLinearVelocity(velocity:tuple())
end

local function dEvaluate(self, dt)
  self.lifetime = self.lifetime - dt
  if self.lifetime <= 0 then
    self.active = false
    return
  end
end

---@return Projectile
function Projectile.new(activate, evaluate, onCollide)
  local self = setmetatable({}, Projectile)
  self.activate    = activate or dActivate
  self.evaluate    = evaluate or dEvaluate
  self.onCollide   = onCollide
  self.active      = false
  self.lifetime    = 0
  self.source      = Vector2.zero()
  self.position    = Vector2.zero()
  self.destination = Vector2.zero()
  self.delta       = Vector2.zero()
  return self
end

function Projectile:clone()
  return Projectile.new(self.activate, self.evaluate, self.onCollide)
end

function Projectile:reset()
  if self.active then
    self.active = false
    self.lifetime = 0
    self.body:destroy()
    self.body = nil
    self.fixture = nil
  end
end

return Projectile

