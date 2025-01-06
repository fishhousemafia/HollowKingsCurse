local Weapon = {}
Weapon.__index = Weapon

function Weapon.load()
    local self = setmetatable({}, Weapon)
    self.image = "smallBullet"
    self.cooldown = 0
    self.count = 1
    self.onFire = function (start, target)
        self.count = self.count + 1
        self.cooldown = 1/20
        if self.count > 10 then
            self.count = 1
            self.cooldown = 1
        end
        local translation = 6
        local rotation = math.pi / 12
        local unit = (target - start):getNormalized()
        local right = start:clone()
        local left = start:clone()
        right.x = right.x + (-unit.y * translation)
        right.y = right.y + (unit.x * translation)
        left.x = left.x + (unit.y * translation)
        left.y = left.y + (-unit.x * translation)
        return {
            {
                id = "base",
                position = start:clone(),
                data = {
                    unit = unit
                }
            },
            {
                id = "right",
                position = right,
                data = {
                    unit = unit:getRotated(rotation)
                }
            },
            {
                id = "left",
                position = left,
                data = {
                    unit = unit:getRotated(-rotation)
                }
            }
        }
    end
    self.eval = function (bullet, dt)
        if bullet.lifetime > 1.5 then
            bullet.destroy = true
        end
        local speed = 100
        local delta = bullet.data.unit * dt * speed
        bullet.position = bullet.position + delta
    end
    return self
end

return Weapon