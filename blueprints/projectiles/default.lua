local kind = (require "core.Utils").kind
local Vector2 = require "math.Vector2"
local Projectile = require "objects.Projectile"

local function activate(self, source, destination, collisionWorld, friendly)
  local angle      = source:angle(destination, true)
  self.angleVector = Vector2.new(math.cos(angle), math.sin(angle))
  self.speed       = 180
  self.velocity    = self.angleVector * self.speed
  self.active      = true
  self.lifetime    = 1
  self.source      = source
  self.destination = destination
  self.body        = love.physics.newBody(collisionWorld, source.x, source.y, "dynamic")
  local shape      = love.physics.newRectangleShape(1, 1)
  self.fixture     = love.physics.newFixture(self.body, shape, 1)
  self.fixture:setUserData(self)
  if friendly then
    self.fixture:setCategory(_G.COLLISION_CATEGORIES.FRIEND_P)
    self.fixture:setMask(_G.COLLISION_CATEGORIES.FRIEND, _G.COLLISION_CATEGORIES.FRIEND_P)
  else
    self.fixture:setCategory(_G.COLLISION_CATEGORIES.ENEMY_P)
    self.fixture:setMask(_G.COLLISION_CATEGORIES.ENEMY, _G.COLLISION_CATEGORIES.ENEMY_P)
  end
  self.body:setBullet(true)
  self.body:setLinearVelocity(self.velocity:tuple())
end

local function evaluate(self, dt)
  self.lifetime = self.lifetime - dt
  if self.lifetime <= 0 then
    self.active = false
    return
  end

  self.speed = self.speed - 1.5
  self.velocity = self.angleVector * self.speed
  self.body:setLinearVelocity(self.velocity:tuple())
end

local function collide(self, contacts)
  local actor
  for _, contact in pairs(contacts) do
    local a, b = contact:getFixtures()
    a, b = a:getUserData(), b:getUserData()
    if kind(a) == "Actor" then
      actor = a
    end
    if kind(b) == "Actor" then
      actor = b
    end
  end
  if actor ~= nil then
    actor.health = actor.health - 10
  end
  self.active = false
end

return function()
  return Projectile.new(activate, evaluate, collide)
end

