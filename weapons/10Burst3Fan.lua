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
    self.count = 1
    self.onFire = function (sx, sy, tx, ty)
        self.count = self.count + 1
        self.cooldown = 1/20
        if self.count > 10 then
            self.count = 1
            self.cooldown = 1
        end
        local unitX, unitY = getNormalized(sx, sy, tx, ty)
        local rightX = sx + (-unitY * 6)
        local rightY = sy + (unitX * 6)
        local leftX = sx + (unitY * 6)
        local leftY = sy + (-unitX * 6)
        return {
            {
                id = "base",
                x = sx,
                y = sy,
            },
            {
                id = "right",
                x = rightX,
                y = rightY
            },
            {
                id = "left",
                x = leftX,
                y = leftY
            }
        }
    end
    self.eval = function (bullet, dt)
        if bullet.lifetime > 1.5 then
            bullet.destroy = true
        end
        if  bullet.set == nil then
            if bullet.id == "base" then
                bullet.unitX, bullet.unitY = getNormalized(bullet.sx, bullet.sy, bullet.tx, bullet.ty)
            end
            if bullet.id == "right" then
                local unitX, unitY = getNormalized(bullet.sx, bullet.sy, bullet.tx, bullet.ty)
                local rad = math.atan2(unitY, unitX)
                bullet.unitX = math.cos(rad + math.pi / 12)
                bullet.unitY = math.sin(rad + math.pi / 12)
            end
            if bullet.id == "left" then
                local unitX, unitY = getNormalized(bullet.sx, bullet.sy, bullet.tx, bullet.ty)
                local rad = math.atan2(unitY, unitX)
                bullet.unitX = math.cos(rad - math.pi / 12)
                bullet.unitY = math.sin(rad - math.pi / 12)
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