local ServiceLocator = require "core.ServiceLocator"
local kind = (require "core.Utils").kind

---@class ProjectileManager
---@field private _active Projectile[]
---@field private _pool Projectile[]
local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

function ProjectileManager.new()
  local self = setmetatable({}, ProjectileManager)
  self._active = {}
  self._pool = {}

  return self
end

function ProjectileManager:spawn(proj, collisionWorld, friendly)
  local p = (#self._pool > 0) and table.remove(self._pool) or proj:clone()
  p.activate  = proj.activate
  p.evaluate  = proj.evaluate
  p.onCollide = proj.onCollide
  p:activate(proj.source, proj.destination, collisionWorld, friendly)
  self._active[#self._active+1] = p
  return p
end

function ProjectileManager:update(dt)
  local list = self._active
  local j = 1
  for i = 1, #list do
    local p = list[i]
    if p and p.active then
      p:evaluate(dt)
      local hit = p.body:getContacts()
      if #hit > 0 then
        if p.onCollide then p:onCollide(hit) end
        --p.active = false
      end
      if p.active then
        list[j] = p; j = j + 1
      else
        p:reset()
        self._pool[#self._pool+1] = p
      end
    elseif p and not p.active then
      p:reset()
      self._pool[#self._pool+1] = p
    end
  end
  for k = j, #list do list[k] = nil end
end

---@return Projectile[]
function ProjectileManager:getAll()
  local result = {}
  for i = 1, #self._active do
    result[i] = self._active[i]
  end
  return result
end

function ProjectileManager:count()
  return #self._active
end

ServiceLocator:register("ProjectileManager", ProjectileManager.new())
return ProjectileManager

