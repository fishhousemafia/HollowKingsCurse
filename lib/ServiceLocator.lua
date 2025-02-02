---@class ServiceLocator
---@field private __index table
---@field private kind string
---@field services table
local ServiceLocator = {
  __kind = "ServiceLocator",
  services = {},
}
ServiceLocator.__index = ServiceLocator

---@param service table
---@return table
function ServiceLocator:register(service)
  self.services[service.__kind] = service.new()
  return self.services[service.__kind]
end

---@param name string
---@return table
function ServiceLocator:get(name)
  local meta = {
    __index = function (_, k)
      return self.services[name][k]
    end,
  }
  return setmetatable({}, meta)
end

---@return ServiceLocator
return ServiceLocator
