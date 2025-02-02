---@class EventBus
---@field private __index EventBus
---@field private kind string
---@field listeners table
local EventBus = { __kind = "EventBus" }
EventBus.__index = EventBus

---@return EventBus
function EventBus.new()
  local self = setmetatable({}, EventBus)
  self.listeners = {}
  return self
end

---@param event string
---@param callback function
function EventBus:subscribe(event, callback)
  if not self.listeners[event] then
    self.listeners[event] = {}
  end
  table.insert(self.listeners[event], callback)
end

---@param event string
---@param ... any
function EventBus:emit(event, ...)
  if self.listeners[event] then
    for _, callback in pairs(self.listeners[event]) do
      callback(...)
    end
  end
end

return EventBus
