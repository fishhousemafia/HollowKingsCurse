local Utility = {}
Utility.__index = Utility

function Utility.map(minIn, maxIn, minOut, maxOut, value)
    local result = minOut + (maxOut - minOut) * ((value - minIn) / (maxIn - minIn))
    local percent = (result - minOut) / (maxOut - minOut)
    return result, percent
end

function Utility.checkCollision(pos1, size1, pos2, size2)
  return pos1.x < pos2.x + size2.x and
         pos2.x < pos1.x + size1.x and
         pos1.y < pos2.y + size2.y and
         pos2.y < pos1.y + size1.y
end

return Utility