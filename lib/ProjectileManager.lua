---@class ProjectileManager
---@field pool Projectile[]
local ProjectileManager = { __kind = "ProjectileManager" }
ProjectileManager.__index = ProjectileManager

function ProjectileManager.new()
  local self = setmetatable({}, ProjectileManager)
  self.pool = {}
  return self
end

function ProjectileManager:add(projectile)
  table.insert(self.pool, projectile)
end

function ProjectileManager:evaluate(dt)
  for idx, projectile in pairs(self.pool) do
    projectile:evaluate(dt)
    if not projectile.active then
      table.remove(self.pool, idx)
    end
  end
end

function ProjectileManager:iterate()
  if #self.pool == 0 then
    return function () end
  end

  local idx = #self.pool
  return function ()
    if idx >= 0 and self.pool[idx] then
      local projectile = self.pool[idx]
      idx = idx - 1
      return projectile
    end
  end
end

return ProjectileManager
