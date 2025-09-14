local ServiceLocator = require "core.ServiceLocator"
local eventBus = ServiceLocator:get("EventBus")

---@class Character
---@field private __kind string
---@field animation Animation
---@field weapon Weapon
---@field world love.World
---@field body love.Body
---@field shape love.Shape
---@field fixture love.Fixture
---@field subs function[]
---@field onUpdate fun(self: Character, dt, number)
---@field isEnabled boolean
local Character = { __kind = "Character" }
Character.__index = Character

---@return Character
function Character.new(animation, weapon, onUpdate)
  local self = setmetatable({}, Character)
  self.animation = animation
  self.weapon = weapon
  self.onUpdate = onUpdate
  self.isEnabled = false

  return self
end

function Character:enable(world, position)
  self.isEnabled = true

  self.world = world
  self.body = love.physics.newBody(world, position.x, position.y, "dynamic")
  self.shape = love.physics.newRectangleShape(8, 8)
  self.fixture = love.physics.newFixture(self.body, self.shape, 1)

  self.subs = {}
  table.insert(self.subs, eventBus:subscribe("update", function(dt) self:onUpdate(dt) end))
  table.insert(self.subs, eventBus:subscribe("beginContact", function(event) self:onBeginContact(event.fixture1, event.fixture2, event.contact) end))
end

function Character:onBeginContact(fixture1, fixture2, contact)
  print(fixture1)
  print(fixture2)
  print(contact)
end

return Character
