local Weapon = {}
Weapon.__index = Weapon

function Weapon.load()
    local self = setmetatable({}, Weapon)
    self.image = "bullet"
    self.cooldown = 0
    self.onFire = function (start, target)
        self.cooldown = 1/3
        local unit = (target - start):getNormalized()
        return {
            {
                id = "base",
                position = start:clone(),
                data = {
                    unit = unit,
                    speed = 10
                }
            },
        }
    end
    self.eval = function (bullet, dt)
        if bullet.lifetime > 1.5 then
            bullet.destroy = true
        end
        local delta = bullet.data.unit * dt * bullet.data.speed
        bullet.position = bullet.position + delta
        bullet.data.speed = bullet.data.speed + 2
    end
    return self
end

return Weapon