---@class MessageQueue
---@field private __kind string
---@field queues table
local MessageQueue = { __kind = "MessageQueue" }
MessageQueue.__index = MessageQueue

---@return MessageQueue
function MessageQueue.new()
  local self = setmetatable({}, MessageQueue)
  self.queues = {}
  return self
end

---@param queue string
---@param message string
function MessageQueue:push(queue, message)
  if not self.queues[queue] then
    self.queues[queue] = {}
  end
  table.insert(self.queues[queue], message)
end

---@param queue string
---@return any
function MessageQueue:pop(queue)
  local message = nil
  if self.queues[queue] then
    local idx = #self.queues[queue]
    message = self.queues[queue][idx]
    self.queues[queue][idx] = nil
  end
  return message
end

---@param queue string
---@return boolean
function MessageQueue:hasData(queue)
  if #self.queues[queue] > 0 then
    return true
  end
  return false
end

---@param queue string
---@return function | nil
function MessageQueue:collect(queue)
  if not self.queues[queue] then
    return function() end
  end

  return function()
    if self:hasData(queue) then
      return self:pop(queue)
    end
  end
end


return MessageQueue
