local ServiceLocator = require "core.ServiceLocator"
local actorManager = ServiceLocator:get("ActorManager")
local eventBus = ServiceLocator:get("EventBus")

---@class Actor
---@field private __kind string
---@field animation Animation
---@field weapon Weapon
---@field world love.World
---@field body love.Body
---@field fixture love.Fixture
---@field subs function[]
---@field onUpdate fun(self: Actor, dt, number)
---@field health number
---@field isEnabled boolean
---@field friendly boolean
local Actor = { __kind = "Actor" }
Actor.__index = Actor

---@return Actor
function Actor.new(animation, weapon, onUpdate)
  local self = setmetatable({}, Actor)
  self.animation = animation
  self.weapon = weapon
  self.onUpdate = onUpdate
  self.isEnabled = false
  self.health = 100
  self.friendly = false

  return self
end

function Actor:enable(world, position, friendly)
  self.isEnabled = true
  self.friendly = friendly or false

  self.world = world
  self.body = love.physics.newBody(world, position.x, position.y, "dynamic")
  local shape = love.physics.newRectangleShape(4, 4)
  self.fixture = love.physics.newFixture(self.body, shape, 1)
  self.fixture:setUserData(self)
  if self.friendly then
    self.fixture:setCategory(_G.COLLISION_CATEGORIES.FRIEND)
    self.fixture:setMask(_G.COLLISION_CATEGORIES.FRIEND, _G.COLLISION_CATEGORIES.ENEMY, _G.COLLISION_CATEGORIES.FRIEND_P)
  else
    self.fixture:setCategory(_G.COLLISION_CATEGORIES.ENEMY)
    self.fixture:setMask(_G.COLLISION_CATEGORIES.FRIEND, _G.COLLISION_CATEGORIES.ENEMY, _G.COLLISION_CATEGORIES.ENEMY_P)
  end

  self.weapon.world = world
  self.weapon.friendly = friendly

  self.subs = {}
  table.insert(self.subs, eventBus:subscribe("beginContact", function(event) self:_onBeginContact(event.fixture1, event.fixture2, event.contact) end))

  actorManager:add(self)
end

function Actor:disable()
  self.isEnabled = false
  self.body:destroy()
  self.body = nil
  self.fixture = nil
end
function Actor:_onUpdate(dt)
  if self.health <= 0 then
    self:disable()
    actorManager:remove(self)
  else
    self:onUpdate(dt)
  end
end

function Actor:_onBeginContact(fixture1, fixture2, contact)
end

return Actor
