local Weapon = {}
Weapon.__index = Weapon

---@class Weapon
---@field context Context
---@field weapon table
---@field image love.Image
---@field cooldown number
---@field onFire function
---@field eval function
---@field bullets table[]
---@functions fire fun(sx: integer, sy: integer, tx: integer, ty: integer)
---@functions evaluate fun(dt: number)

function Weapon.new(context, weapon)
    local self = setmetatable({}, Weapon)
    self.context = context
    self.weapon = weapon.load()
    self.image = self.context.imageTable[self.weapon.image]
    self.bullets = {}
    return self
end

function Weapon:fire(sx, sy, tx, ty)
    if self.weapon.cooldown > 0 then
        return
    end
    local volley = self.weapon.onFire(sx, sy, tx, ty)
    for _, bullet in ipairs(volley) do
        table.insert(self.bullets, {
            id = bullet.id,
            x = bullet.x,
            y = bullet.y,
            sx = sx,
            sy = sy,
            tx = tx,
            ty = ty,
            lifetime = 0,
            destroy = false
        })
    end
end

function Weapon:evaluate(dt)
    self.weapon.cooldown = self.weapon.cooldown - dt
    for i, bullet in ipairs(self.bullets) do
        if bullet.destroy then
            table.remove(self.bullets, i)
            goto continue
        end
        self.weapon.eval(bullet, dt)
        bullet.lifetime = bullet.lifetime + dt
        ::continue::
    end
end

return Weapon