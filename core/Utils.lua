local Utils = {}

function Utils.kind(o)
  local t = type(o)
  if t == "table" or t == "cdata" then
    return o.__kind or t
  end
  return t
end

function Utils.stringify(o)
  local t = type(o)

  if t ~= "table" then
    return tostring(o)
  end

  local k = Utils.kind(o)
  local builder = "{"
  if k ~= "table" then
    builder = k .. builder
  end

  local loop = false
  for key, v in pairs(o) do
    if key == "__index" then
      goto continue
    end
    loop = true
    builder = builder .. " " .. key .. " = " .. Utils.stringify(v) .. ","
    ::continue::
  end

  if loop then
    return builder .. " }"
  end
  return builder .. "}"
end

function Utils.setFinalizer(t, fn)
  local proxy = newproxy(true)
  getmetatable(proxy).__gc = function () fn(t) end
  t.__proxy = proxy
end

return Utils
