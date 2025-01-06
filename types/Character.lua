local Character = {}
Character.__index = Character

---@class Character
---@field context Context
---@field imageTable love.Image[]
---@field x integer
---@field y integer
---@field speed integer
---@field weapon Weapon
---@field image love.Image
---@field facing string
---@functions move fun(magX: integer, magY: integer, mx: integer, my: integer, dt: number)

function Character.new(context, images, x, y, speed, weapon)
    local self = setmetatable({}, Character)
    self.context = context
    self.imageTable = images
    self.x = x
    self.y = y
    self.speed = speed
    self.weapon = weapon
    self.image = self.imageTable["down"]
    self.facing = "none"
    return self
end

function Character:move(magX, magY, dispX, dispY, dt)
    if magX == 0 and magY == 0 and dispX == 0 and dispY == 0 then
        return
    end
    local unitX = magX
    local unitY = magY
    if math.abs(magX) + math.abs(magY) ~= 1 then
        local normalizeFactor = math.sqrt((magX * magX) + (magY * magY))
        if magX ~= 0 then
            unitX = magX / normalizeFactor
        end
        if magY ~= 0 then
            unitY = magY / normalizeFactor
        end
    end
    local dx = unitX * dt * self.speed
    local dy = unitY * dt * self.speed
    self.x = self.x + dx + (dispX * dt)
    self.y = self.y + dy + (dispY * dt)
    self.x = math.max(0, math.min(self.context.w, self.x))
    self.y = math.max(0, math.min(self.context.h, self.y))
    if magY < 0 and (self.facing == "none" or (math.abs(magY) > math.abs(magX))) then
        self.image = self.imageTable["up"]
        self.facing = "up"
    end
    if magY > 0 and (self.facing == "none" or (math.abs(magY) > math.abs(magX))) then
        self.image = self.imageTable["down"]
        self.facing = "down"
    end
    if magX < 0 and (self.facing == "none" or (math.abs(magX) > math.abs(magY))) then
        self.image = self.imageTable["left"]
        self.facing = "left"
    end
    if magX > 0 and (self.facing == "none" or (math.abs(magX) > math.abs(magY))) then
        self.image = self.imageTable["right"]
        self.facing = "right"
    end
end

return Character