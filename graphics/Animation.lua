---@class Animation
---@field private __kind string
---@field imageData love.ImageData
---@field width number
---@field height number
---@field animate fun(animation: Animation, animationName: string, dt: number)
---@field spriteSheet love.Image
---@field quads love.Quad[]
---@field quadIndex number
---@field currentTime number
---@field currentAnimation string
---@field animationDict { [string]: { row: number, fps: number } }
---@field currentQuad love.Quad
local Animation = { __kind = "Character" }
Animation.__index = Animation

---@return Animation
function Animation.new(imageData, width, height, animationDict, defaultAnimation)
  local self = setmetatable({}, Animation)
  self.imageData = imageData
  self.width = width
  self.height = height
  self.animationDict = animationDict
  self.spriteSheet = love.graphics.newImage(imageData)
  self.quads = {};
  self.quadIndex = 1
  self.currentTime = 0

  for y = 0, self.imageData:getHeight() - height, height do
    local row = {}
    for x = 0, self.imageData:getWidth() - width, width do
      local isEmpty = true
      for yy = y, self.height + y - 1 do
        for xx = x, self.width + x - 1 do
          local r, g, b, a = self.imageData:getPixel(xx, yy)
          if (r ~= 0 or g ~= 0 or b ~= 0) and a > 0 then
            isEmpty = false
          end
        end
      end
      if not isEmpty then
        table.insert(row, love.graphics.newQuad(x, y, self.width, self.height, self.imageData:getDimensions()))
      end
    end
    table.insert(self.quads, row)
  end

  self.currentAnimation = defaultAnimation
  self.currentQuad = self.quads[animationDict[defaultAnimation].row][1]

  return self
end

function Animation:animate(animationName, dt)
  local currentAnimationTable = self.animationDict[animationName]
  if self.currentAnimation == animationName then
    self.currentTime = self.currentTime + dt
    if self.currentTime > 1 / currentAnimationTable.fps then
      self.currentTime = 0
      self.quadIndex = self.quadIndex + 1
      if self.quadIndex > #self.quads[currentAnimationTable.row] then
        self.quadIndex = 1
      end
      self.currentQuad = self.quads[currentAnimationTable.row][self.quadIndex]
    end
  else
    self.currentAnimation = animationName
    self.currentTime = 0
    self.quadIndex = 1
    self.currentQuad = self.quads[currentAnimationTable.row][1]
  end
end

return Animation
