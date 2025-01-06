local Context = {}
Context.__index = Context

---@class Context
---@field w integer
---@field h integer
---@field scale integer

function Context.new(w, h, scale, imageTable)
    local self = setmetatable({}, Context)
    self.w = w
    self.h = h
    self.scale = scale
    self.imageTable = imageTable
    return self
end

return Context