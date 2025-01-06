local Utility = {}
Utility.__index = Utility

function Utility.map(minIn, maxIn, minOut, maxOut, value)
    local result = minOut + (maxOut - minOut) * ((value - minIn) / (maxIn - minIn))
    local percent = (result - minOut) / (maxOut - minOut)
    return result, percent
end

function Utility.checkCollision(pos1, size1, pos2, size2)
  return (pos1.x - size1.x / 2) < (pos2.x + size2.x / 2)
     and (pos2.x - size2.x / 2) < (pos1.x + size1.x / 2)
     and (pos1.y - size1.y / 2) < (pos2.y + size2.y / 2)
     and (pos2.y - size2.y / 2) < (pos1.y + size1.y / 2)
end

return Utility