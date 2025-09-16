local ServiceLocator = require "core.ServiceLocator"

---@class ActorManager
---@field private _list Map[]
---@field private _idx table<Map, integer>  -- reverse index for O(1) remove
---@field updateEnabledOnly boolean            -- if true, skip updates when !isEnabled
local ActorManager = {}
ActorManager.__index = ActorManager

function ActorManager.new()
  local self = setmetatable({}, ActorManager)
  self._list = {}
  self._idx = {}

  return self
end

---@param actor Map
function ActorManager:add(actor)
  if self._idx[actor] then
    return
  end

  local i = #self._list + 1
  self._list[i] = actor
  self._idx[actor] = i
  if actor.isEnabled == nil then
    actor.isEnabled = true
  end
end

---@param actors Map[]
function ActorManager:addAll(actors)
  for i = 1, #actors do self:add(actors[i]) end
end

---@param actor Map
function ActorManager:remove(actor)
  local i = self._idx[actor]
  if not i then
    return
  end

  local last = self._list[#self._list]
  self._list[i] = last
  self._list[#self._list] = nil
  self._idx[actor] = nil
  if last and last ~= actor then
    self._idx[last] = i
  end
end

function ActorManager:clear()
  for i = 1, #self._list do
    self._list[i] = nil
  end
  for k in pairs(self._idx) do
    self._idx[k] = nil
  end
end

function ActorManager:count() return #self._list end

function ActorManager:countEnabled()
  local n = 0
  for i = 1, #self._list do
    if self._list[i].isEnabled then
      n = n + 1
    end
  end
  return n
end

---@return Map[]
function ActorManager:getAll()
  local out, n = {}, #self._list
  for i = 1, n do
    out[i] = self._list[i]
  end
  return out
end

---@return Map[]
function ActorManager:getEnabled()
  local out, j = {}, 1
  for i = 1, #self._list do
    local a = self._list[i]
    if a.isEnabled then
      out[j] = a
      j = j + 1
    end
  end
  return out
end

function ActorManager:setEnabled(actor, enabled)
  if not self._idx[actor] then
    return
  end
  actor.isEnabled = enabled
end

function ActorManager:update(dt)
  local list = self._list
  local i = 1
  while i <= #list do
    local a = list[i]
    if a and a.isEnabled then
      a:_onUpdate(dt)
      -- If 'a' removed itself, list[i] now holds a different actor; process it next.
      if list[i] == a then
        i = i + 1
      end
    else
      i = i + 1
    end
  end
end

ServiceLocator:register("ActorManager", ActorManager.new())
return ActorManager

