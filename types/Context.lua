local Context = {}
Context.__index = Context

---@class Context
---@field w integer
---@field h integer
---@field scale integer
---@field imageTable love.Image[]
---@field characterTable Character[]
---@field weaponTable Weapon[]
---@field bulletTable table[]

function Context.new(w, h, scale)
    local self = setmetatable({}, Context)
    self.width = w
    self.height = h
    self.scale = scale
    self.imageTable = {}
    self.characterTable = {}
    self.weaponTable = {}
    self.bulletTable = {}
    return self
end

return Context