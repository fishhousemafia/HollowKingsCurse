local Vector = require("types.Vector")

local Character = {}
Character.__index = Character

---@class Character
---@field context Context
---@field imageTable love.Image[]
---@field position Vector
---@field speed integer
---@field weapon Weapon
---@field image love.Image
---@field facing string
---@functions move fun(magnitudeX: integer, magnitudeY: integer, displacementX: integer, displacementY: integer, dt: number)

function Character.new(context, images, position, speed, weapon)
    local self = setmetatable({}, Character)
    self.context = context
    self.imageTable = images
    self.position = position
    self.speed = speed
    self.weapon = weapon
    self.image = self.imageTable["down"]
    self.facing = "none"
    return self
end

function Character:move(direction, displacement, dt)
    if direction == Vector.new(0, 0) and displacement == Vector.new(0, 0) then
        return
    end
    if direction:isNormalized() == false then
        direction = direction:getNormalized()
    end
    local unit = direction:getNormalized()
    local delta = unit * dt * self.speed
    self.position = self.position + delta + (displacement * dt)
    self.position.x = math.max(0, math.min(self.context.width, self.position.x))
    self.position.y = math.max(0, math.min(self.context.height, self.position.y))
    if direction.y < 0 and (self.facing == "none" or (math.abs(direction.y) > math.abs(direction.x))) then
        self.image = self.imageTable["up"]
        self.facing = "up"
    end
    if direction.y > 0 and (self.facing == "none" or (math.abs(direction.y) > math.abs(direction.x))) then
        self.image = self.imageTable["down"]
        self.facing = "down"
    end
    if direction.x < 0 and (self.facing == "none" or (math.abs(direction.x) > math.abs(direction.y))) then
        self.image = self.imageTable["left"]
        self.facing = "left"
    end
    if direction.x > 0 and (self.facing == "none" or (math.abs(direction.x) > math.abs(direction.y))) then
        self.image = self.imageTable["right"]
        self.facing = "right"
    end
end

return Character