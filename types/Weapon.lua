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
---@functions fire fun(startX: number, startY: number, targetX: number, targetY: number)
---@functions evaluate fun(dt: number)

function Weapon.new(context, weapon)
    local self = setmetatable({}, Weapon)
    self.context = context
    self.weapon = weapon.load()
    self.image = self.context.imageTable[self.weapon.image]
    self.bullets = {}
    return self
end

function Weapon:fire(start, target)
    if self.weapon.cooldown > 0 then
        return
    end
    local volley = self.weapon.onFire(start, target)
    for _, bullet in ipairs(volley) do
        table.insert(self.context.bulletTable, {
            id = bullet.id,
            position = bullet.position,
            data = bullet.data,
            eval = self.weapon.eval,
            image = self.context.imageTable[bullet.image] or self.image,
            start = start,
            target = target,
            lifetime = 0,
            destroy = false
        })
    end
end

function Weapon:evaluate(dt)
    self.weapon.cooldown = self.weapon.cooldown - dt
end

return Weapon