---@class ServiceLocator
---@field private __kind string
---@field private services table<string, any>
local ServiceLocator = {
  __kind = "ServiceLocator",
  services = {},
}
ServiceLocator.__index = ServiceLocator

-- Register a preconfigured instance under a name.
-- Errors if the name already exists unless opts.overwrite == true.
---@param name string
---@param instance any
---@param opts { overwrite?: boolean }|nil
---@return any
function ServiceLocator:register(name, instance, opts)
  assert(type(name) == "string" and name ~= "", "ServiceLocator.register: name must be a non-empty string")
  assert(instance ~= nil, "ServiceLocator.register: instance must not be nil")
  opts = opts or {}
  if self.services[name] and not opts.overwrite then
    error(("ServiceLocator.register: '%s' already registered (use overwrite=true to replace)"):format(name))
  end
  self.services[name] = instance
  return instance
end

-- Strict accessor: throws if missing.
---@param name string
---@return any
function ServiceLocator:get(name)
  local svc = self.services[name]
  if svc == nil then
    error(("ServiceLocator.get: service '%s' not registered"):format(name))
  end
  return svc
end

-- Non-throwing accessor: returns nil if missing.
---@param name string
---@return any|nil
function ServiceLocator:try_get(name)
  return self.services[name]
end

-- Unregister a service. Returns the removed instance or nil.
---@param name string
---@return any|nil
function ServiceLocator:unregister(name)
  local old = self.services[name]
  self.services[name] = nil
  return old
end

-- Replace convenience: overwrite must be explicit to signal intent.
---@param name string
---@param instance any
---@return any
function ServiceLocator:replace(name, instance)
  return self:register(name, instance, { overwrite = true })
end

-- For tests/bootstrap tooling: list names (shallow copy).
---@return string[]
function ServiceLocator:list()
  local out = {}
  for k,_ in pairs(self.services) do out[#out+1] = k end
  table.sort(out)
  return out
end

-- For tests only: clear all services.
function ServiceLocator:clear()
  for k,_ in pairs(self.services) do self.services[k] = nil end
end

return ServiceLocator

