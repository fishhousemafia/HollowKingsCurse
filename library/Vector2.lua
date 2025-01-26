local kind = require("library/Utils").kind
local setFinalizer = require("library/Utils").setFinalizer
local stringify = require("library/Utils").stringify

---@class Vector2
---@field private __index Vector2
---@field private kind string
---@field x number
---@field y number
---@field private dispatched boolean
---@field private seq number
local Vector2 = { kind = "Vector2" }
Vector2.__index = Vector2

_G.VEC_CREATE = 0
_G.VEC_DISPATCH = 0
_G.VEC_POOL = 0
_G.VEC_READY = 0

local active = setmetatable({}, { __mode = "v" })
local inactive = {}
local seq = 0
local finalizer = function(self)
  self.dispatched = false
  table.insert(inactive, self)
  active[self.seq] = nil
end

---@param x number
---@param y number
---@return Vector2 # The Vector2 data type represents a 2D value with direction and magnitude.
function Vector2.new(x, y)
  local self = nil
  _G.VEC_DISPATCH = _G.VEC_DISPATCH + 1
  if #inactive == 0 then
    seq = seq + 1
    _G.VEC_CREATE = _G.VEC_CREATE + 1
    _G.VEC_POOL = seq
    self = setmetatable({}, Vector2)
    self.seq = seq
  else
    self = table.remove(inactive)
    _G.VEC_READY = #inactive
  end
  active[self.seq] = self
  setFinalizer(self, finalizer)
  self.x = x or 0
  self.y = y or 0
  self.dispatched = true
  return self
end

function Vector2:clone()
  return Vector2.new(self:tuple())
end

---@return Vector2 # A Vector2 with a magnitude of zero.
function Vector2.zero()
  return Vector2.new(0, 0)
end

---@return Vector2 # A Vector2 with a value of 1 on every axis.
function Vector2.one()
  return Vector2.new(1, 1)
end

---@return Vector2 # A Vector2 with a value of 1 on the X axis.
function Vector2.xAxis()
  return Vector2.new(1, 0)
end

---@return Vector2 # A Vector2 with a value of 1 on the Y axis.
function Vector2.yAxis()
  return Vector2.new(0, 1)
end

---@return number, number # Returns the X and Y components of a Vector2.
function Vector2:tuple()
  return self.x, self.y
end

---@return number # The length of the Vector2.
function Vector2:magnitude()
  return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

---@return Vector2 # A normalized copy of the Vector2.
function Vector2:unit()
  local m = self:magnitude()
  if m == 0 then
    return Vector2.zero()
  end
  return self / m
end

---@param other Vector2
---@return number # Returns the cross product of the two vectors.
function Vector2:cross(other)
  return self.x * other.y - other.x * self.y
end

---@return Vector2 # Returns a new vector from the absolute values of the original's components.
function Vector2:abs()
  return Vector2.new(math.abs(self.x), math.abs(self.y))
end

---@return Vector2 # Returns a new vector from the ceiling of the original's components.
function Vector2:ceil()
  return Vector2.new(math.ceil(self.x), math.ceil(self.y))
end

---@return Vector2 # Returns a new vector from the floor of the original's components.
function Vector2:floor()
  return Vector2.new(math.floor(self.x), math.floor(self.y))
end

---@return Vector2 # Returns a new vector from the sign (-1, 0, or 1) of the original's components.
function Vector2:sign()
  local x = 0
  local y = 0
  if self.x < 0 then
    x = -1
  elseif self.x > 0 then
    x = 1
  end
  if self.y < 0 then
    y = -1
  elseif self.y > 0 then
    y = 1
  end
  return Vector2.new(x, y)
end

---@param other Vector2
---@param isSigned boolean
---@return number # Returns the angle in radians between the two vectors. Specify true for the optional isSigned boolean if you want a signed angle.
function Vector2:angle(other, isSigned)
  isSigned = isSigned or false
  local rad = math.atan2(other.y - self.y, other.x - self.x)
  if isSigned then
    return rad
  end
  return math.abs(rad)
end

---@param other Vector2
---@return number # Returns a scalar dot product of the two vectors.
function Vector2:dot(other)
  return self.x * other.x + self.y * other.y
end

---@param other Vector2
---@param alpha number
---@return Vector2 # Returns a Vector2 linearly interpolated between this Vector2 and the given goal by the given alpha.
function Vector2:lerp(other, alpha)
  local x = self.x + alpha * (other.x - self.x)
  local y = self.y + alpha * (other.y - self.y)
  return Vector2.new(x, y)
end

---@param ... Vector2[]
---@return Vector2 # Returns a Vector2 with each component as the highest among the respective components of the provided Vector2 objects.
function Vector2:max(...)
  local xMax, yMax = -math.huge, -math.huge
  for _, v in ipairs({self, ...}) do
    if v.x > xMax then
      xMax = v.x
    end
    if v.y > yMax then
      yMax = v.y
    end
  end
  return Vector2.new(xMax, yMax)
end

---@param ... Vector2[]
---@return Vector2 # Returns a Vector2 with each component as the lowest among the respective components of the provided Vector2 objects.
function Vector2:min(...)
  local xMin, yMin = math.huge, math.huge
  for _, v in ipairs({self, ...}) do
    if v.x < xMin then
      xMin = v.x
    end
    if v.y < yMin then
      yMin = v.y
    end
  end
  return Vector2.new(xMin, yMin)
end

---@private
function Vector2.multiplyScalar(a, b)
  return Vector2.new(a.x * b, a.y * b)
end

---@private
function Vector2.multiplyVector(a, b)
  return Vector2.new(a.x * b.x, a.y * b.y)
end

---@private
function Vector2.divideScalar(a, b)
  return Vector2.new(a.x / b, a.y / b)
end

---@private
function Vector2.divideVector(a, b)
  return Vector2.new(a.x / b.x, a.y / b.y)
end

---@private
function Vector2.__add(a, b)
  if kind(a) == "Vector2" or kind(b) == "Vector2" then
    return Vector2.new(a.x + b.x, a.y + b.y)
  end
  error("Attempt to add " .. kind(a) .. " to " .. kind(b))
end

---@private
function Vector2.__sub(a, b)
  if kind(a) == "Vector2" or kind(b) == "Vector2" then
    return Vector2.new(a.x - b.x, a.y - b.y)
  end
  error("Attempt to subtract " .. kind(b) .. " from " .. kind(a))
end

---@private
function Vector2.__mul(a, b)
  if kind(a) == "Vector2" and kind(b) == "Vector2" then
    return Vector2.multiplyVector(a, b)
  elseif kind(a) == "number" then
    return Vector2.multiplyScalar(b, a)
  elseif kind(b) == "number" then
    return Vector2.multiplyScalar(a, b)
  end
  error("Attempt to multiply " .. kind(a) .. " with " .. kind(b))
end

---@private
function Vector2.__div(a, b)
  if kind(a) == "Vector2" and kind(b) == "Vector2" then
    return Vector2.divideVector(a, b)
  elseif kind(b) == "number" then
    return Vector2.divideScalar(a, b)
  end
  error("Attempt to divide " .. kind(a) .. " by " .. kind(b))
end

---@private
function Vector2.__unm(a)
  return Vector2.new(-a.x, -a.y)
end

---@private
function Vector2.__eq(a, b)
  if kind(a) == "Vector2" and kind(b) == "Vector2" then
    return a.x == b.x and a.y == b.y
  end
  error("Attempt to compare " .. kind(a) .. " with " .. kind(b))
end

---@private
function Vector2.__ne(a, b)
  if kind(a) == "Vector2" and kind(b) == "Vector2" then
    return not Vector2.__eq(a, b)
  end
  error("Attempt to compare " .. kind(a) .. " with " .. kind(b))
end

---@private
function Vector2.__lt(a, b)
  if kind(a) == "Vector2" and kind(b) == "Vector2" then
    return a.x < b.x and a.y < b.y
  end
  error("Attempt to compare " .. kind(a) .. " with " .. kind(b))
end

---@private
function Vector2.__le(a, b)
  if kind(a) == "Vector2" and kind(b) == "Vector2" then
    return a.x <= b.x and a.y <= b.y
  end
  error("Attempt to compare " .. kind(a) .. " with " .. kind(b))
end

---@private
function Vector2.__tostring(a)
  return stringify(a)
end

return Vector2
