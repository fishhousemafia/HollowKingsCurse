local Vector2 = require "math.Vector2"
local Weapon = require "objects.Weapon"

local function pattern(self, source, destination)
  local out = {}
  local baseAngle = source:angle(destination, true)
  local baseAngleVector = Vector2.new(math.cos(baseAngle), math.sin(baseAngle))
  local coneAngle = math.pi/60
  for i = -2, 2 do
    local bp = self.blueprint:clone()
    local angle = baseAngleVector:rotate(coneAngle * i)
    local far = source + (angle * 1000)
    bp.source = source
    bp.destination = far
    table.insert(out, bp)
  end
  return out
end

local makeProjectile = require "blueprints.projectiles.default"
return function()
  return Weapon.new(makeProjectile(), 0.5, pattern)
end

