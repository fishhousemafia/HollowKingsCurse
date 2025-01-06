local Vector = {}
Vector.__index = Vector

---@class Vector
---@field x number
---@field y number
---@functions getAngle fun(): number
---@functions getMagnitude fun(): number
---@functions getNormalized fun(): Vector
---@functions getRotated fun(rad: number): Vector
---@functions isNormalized fun(): boolean
---@functions clone fun(): Vector
---@functions tuple fun(): number, number

function Vector.new(x, y)
    local self = setmetatable({}, Vector)
    self.x = x or 0
    self.y = y or 0
    return self
end

function Vector:__add(other)
    return Vector.new(self.x + other.x, self.y + other.y)
end

function Vector:__sub(other)
    return Vector.new(self.x - other.x, self.y - other.y)
end

function Vector:__mul(scalar)
    return Vector.new(self.x * scalar, self.y * scalar)
end

function Vector:__div(scalar)
    return Vector.new(self.x / scalar, self.y / scalar)
end

function Vector:__eq(other)
    return self.x == other.x and self.y == other.y
end

function Vector:getAngle()
    return math.atan2(self.y, self.x)
end

function Vector:getMagnitude()
    return math.sqrt((self.x * self.x) + (self.y * self.y))
    
end

function Vector:getNormalized()
    local magnitude = self:getMagnitude()
    if magnitude == 0 then
        return Vector.new(0, 0)
    end
    return Vector.new(self.x / magnitude, self.y / magnitude)
end

function Vector:getRotated(rad)
    local x = self.x * math.cos(rad) - self.y * math.sin(rad)
    local y = self.x * math.sin(rad) + self.y * math.cos(rad)
    return Vector.new(x, y)
end

function Vector:isNormalized()
    return math.abs(self.x) + math.abs(self.y) == 1
end

function Vector:clone()
    return Vector.new(self.x, self.y)
end

function Vector:tuple()
    return self.x, self.y
end

return Vector