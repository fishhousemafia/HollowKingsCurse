local Utils = {}

function Utils.kind(o)
  if type(o) == "table" then
    return o.kind or type(o)
  end
  return type(o)
end

function Utils.stringify(o)
  if type(o) ~= "table" then
    return tostring(o)
  end

  local builder = "{"
  if Utils.kind(o) ~= "table" then
    builder = Utils.kind(o) .. builder
  end

  local loop = false
  for k, v in pairs(o) do
    if k == "__index" then
      goto continue
    end
    loop = true
    builder = builder .. " " .. k .. " = " .. Utils.stringify(v) .. ","
    ::continue::
  end

  if loop then
    return builder .. " }"
  end
  return builder .. "}"
end

function Utils.setFinalizer(t, fn)
   local mt = getmetatable(t) or {}
   setmetatable(t, mt)
   mt.__proxy = newproxy(true)
   getmetatable(mt.__proxy).__gc = function() fn(t) end
end

return Utils
