local Utility = {}
Utility.__index = Utility

---@class Utility

function Utility.map(minIn, maxIn, minOut, maxOut, value)
    return minOut + (maxOut - minOut) * ((value - minIn) / (maxIn - minIn))
end

return Utility