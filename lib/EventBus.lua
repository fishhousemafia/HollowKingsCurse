---@class EventBus
---@field private __kind string
---@field private _map table<string, EventBus.Listener[]>   -- event -> ordered listeners
---@field private _queue EventBus.Enqueued[]                -- queued events for pump()
---@field private _emitting integer                         -- reentrancy depth
---@field private _profiling boolean
local EventBus = { __kind = "EventBus" }
EventBus.__index = EventBus

---@class EventBus.Listener
---@field fn fun(...):nil
---@field once boolean
---@field tag string|nil
---@field priority integer

---@class EventBus.SubscribeOpts
---@field once boolean|nil
---@field tag string|nil
---@field priority integer|nil   # higher runs earlier; default 0

---@class EventBus.Enqueued
---@field name string
---@field args any[]

local function compact(list)
  if not list then return end
  local j = 1
  for i = 1, #list do
    local v = list[i]
    if v then list[j] = v; j = j + 1 end
  end
  for k = j, #list do list[k] = nil end
end

---Create a new EventBus.
---@return EventBus
function EventBus.new()
  local self = setmetatable({}, EventBus)
  self._map = {}
  self._queue = {}
  self._emitting = 0
  self._profiling = false
  return self
end

-- Internal: insert listener in priority order (stable).
---@param list EventBus.Listener[]
---@param l EventBus.Listener
local function insert_by_priority(list, l)
  local p = l.priority or 0
  local n = #list
  local i = n + 1
  -- simple backwards insertion; n is usually small
  while i > 1 and (list[i-1].priority or 0) < p do
    list[i] = list[i-1]
    i = i - 1
  end
  list[i] = l
end

---Subscribe to an event.
---@param name string  -- event name; use "*" to receive all events
---@param fn fun(...):nil
---@param opts EventBus.SubscribeOpts|nil
---@return fun():nil   -- unsubscribe function
function EventBus:subscribe(name, fn, opts)
  assert(type(name) == "string" and name ~= "", "EventBus.subscribe: name must be non-empty string")
  assert(type(fn) == "function", "EventBus.subscribe: fn must be function")
  opts = opts or {}
  local list = self._map[name] or {}
  self._map[name] = list

  local l = {
    fn = fn,
    once = not not opts.once,
    tag = opts.tag,
    priority = opts.priority or 0,
  }
  insert_by_priority(list, l)

  -- Return an unsubscribe closure
  local unsubbed = false
  return function()
    if unsubbed then return end
    unsubbed = true
    -- mark removal; defer hard compaction if emitting
    for i = 1, #list do
      if list[i] == l then
        list[i] = false -- tombstone for safe in-emit removal
        break
      end
    end
    if self._emitting == 0 then
      -- compact now if not in emit
      local j = 1
      for i = 1, #list do
        local v = list[i]
        if v then
          list[j] = v; j = j + 1
        end
      end
      for k = j, #list do list[k] = nil end
    end
  end
end

---Unsubscribe by function or tag.
---@param name string
---@param key fun(...):nil|string  -- the original function or a tag
function EventBus:off(name, key)
  local list = self._map[name]
  if not list then return end
  local byTag = type(key) == "string"
  for i = 1, #list do
    local l = list[i]
    if l and ((byTag and l.tag == key) or (not byTag and l.fn == key)) then
      list[i] = false
    end
  end
end

---Emit immediately. Handlers are isolated via pcall.
---If a handler throws and event ~= "error", forwards (eventName, err) to "error" listeners.
---@param name string
---@param ... any
function EventBus:emit(name, ...)
  local specific = self._map[name]
  local wildcard = self._map["*"]
  if not specific and not wildcard then return end

  self._emitting = self._emitting + 1
  local errorList = (name ~= "error") and self._map["error"] or nil

  local function call_list(list, isWildcard, ...)
    if not list then return end
    for i = 1, #list do
      local L = list[i]
      if L then
        local ok, res
        if isWildcard then
          ok, res = pcall(L.fn, name, ...)
        else
          ok, res = pcall(L.fn, ...)
        end
        if not ok and errorList then
          local err = debug.traceback(res)
          for j = 1, #errorList do local E = errorList[j]; if E then pcall(E.fn, name, err) end end
        end
        if L.once then list[i] = false end
      end
    end
  end

  call_list(specific, false, ...)
  call_list(wildcard, true, ...)

  self._emitting = self._emitting - 1
  if self._emitting == 0 then
    compact(specific)
    compact(wildcard)
  end
end

---Queue an event to be delivered later via :pump().
---@param name string
---@param ... any
function EventBus:queue(name, ...)
  local ev = { name = name, args = { ... } }
  self._queue[#self._queue + 1] = ev
end

---Deliver all queued events in FIFO order.
function EventBus:pump()
  if #self._queue == 0 then return end
  -- move to local and clear quickly (allows re-queue during pump)
  local q = self._queue
  self._queue = {}
  for i = 1, #q do
    local ev = q[i]
    self:emit(ev.name, table.unpack(ev.args, 1, #ev.args))
  end
end

---Number of listeners on an event (or total if name == "*total*").
---@param name string
---@return integer
function EventBus:listenerCount(name)
  if name == "*total*" then
    local n = 0
    for _, list in pairs(self._map) do n = n + #list end
    return n
  end
  local list = self._map[name]
  return list and #list or 0
end

---Remove all listeners (or for one event).
---@param name string|nil
function EventBus:clear(name)
  if name then
    self._map[name] = nil
  else
    for k,_ in pairs(self._map) do self._map[k] = nil end
    self._queue = {}
  end
end

---Enable or disable simple profiling markers.
---@param enabled boolean
function EventBus:setProfiling(enabled) self._profiling = not not enabled end

-- Aliases
EventBus.on  = EventBus.subscribe
EventBus.offBy = EventBus.off

return EventBus

