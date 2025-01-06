local Weapon = {}
Weapon.__index = Weapon

local function getNormalized(sx, sy, tx, ty)
    local magX = tx - sx
    local magY = ty - sy
    local normalizeFactor = math.sqrt((magX * magX) + (magY * magY))
    return magX / normalizeFactor, magY / normalizeFactor
end

function Weapon.load()
    local self = setmetatable({}, Weapon)
    self.image = "bullet"
    self.cooldown = 0
    self.onFire = function (sx, sy, tx, ty)
        self.cooldown = 1/3
        return {
            {
                id = "base",
                x = sx,
                y = sy,
            },
        }
    end
    self.eval = function (bullet, dt)
        if bullet.lifetime > 2 then
            bullet.destroy = true
        end
        if  bullet.set == nil then
            if bullet.id == "base" then
                bullet.unitX, bullet.unitY = getNormalized(bullet.sx, bullet.sy, bullet.tx, bullet.ty)
            end
            bullet.set = true
        end
        local speed = 100
        local dx = bullet.unitX * dt * speed
        local dy = bullet.unitY * dt * speed
        bullet.x = bullet.x + dx
        bullet.y = bullet.y + dy
    end
    return self
end

return Weapon