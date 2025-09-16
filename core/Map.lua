---@class Map
---@field private __kind string
---@field data table
---@field tiles table
---@field tileheight integer
---@field tilewidth integer
---@field batchesPerLayer table<integer, table<string, love.SpriteBatch>>
local Map = { __kind = "Map" }
Map.__index = Map

local function normalize_path(path)
  path = path:gsub("//+", "/"):gsub("/%./", "/")
  local changed
  repeat
    changed = false
    local p; path, p = path:gsub("([^/]+)/%.%./", "")
    if p > 0 then changed = true end
  until not changed
  return path
end


---@return Map
function Map.new(filename)
  local self = setmetatable({}, Map)
  self.data = love.filesystem.load(filename)()
  self.tiles = {}
  self.tileheight = self.data.tileheight
  self.tilewidth = self.data.tilewidth
  self.batchesPerLayer = {}

  local tilesets = {}
  local gidInfo = {}

  local directory = filename:gsub("[^\\/]*.lua$", "")
  local tilesetData = self.data.tilesets
  for i=1, #tilesetData do
    local tileset = tilesetData[i]
    local name = tileset.name
    local gid = tileset.firstgid
    local imageheight = tileset.imageheight
    local imagewidth = tileset.imagewidth
    local tileheight = tileset.tileheight
    local tilewidth = tileset.tilewidth
    local imageFile = normalize_path(directory .. tileset.image)
    local image = love.graphics.newImage(imageFile)
    tilesets[name] = image
    for y=0, (imageheight/tileheight)-1 do
      for x=0, (imagewidth/tilewidth)-1 do
        gidInfo[gid] = {
          quad = love.graphics.newQuad(x*tilewidth, y*tileheight, tilewidth, tileheight, image),
          tileset = name,
        }
        gid = gid + 1
      end
    end
  end

  -- Get the tilesets for each layer and count the number of tiles for each tileset
  local data = self.data
  local layers = data.layers
  local batchesPerLayer = self.batchesPerLayer
  for layerId=1, #layers do
    local layer = layers[layerId]
    local layertype = layer.type
    if layertype == "tilelayer" then
      local width = layer.width
      local height = layer.height
      local layerdata = layer.data
      local tileIdx = 1
      local countPerTileset = {}
      batchesPerLayer[layerId] = {}
      for _=1, height do
        for _=1, width do
          local gid = layerdata[tileIdx]
          tileIdx = tileIdx + 1
          if gid ~= 0 then
            local tileset = gidInfo[gid].tileset
            countPerTileset[tileset] = (countPerTileset[tileset] or 0) + 1
          end
        end
      end

      -- Create sprite batches for each tileset in this layer
      for tileset, count in pairs(countPerTileset) do
        local image = tilesets[tileset]
        batchesPerLayer[layerId][tileset] = love.graphics.newSpriteBatch(image, count)
      end
    end
  end

  -- Populate sprite batches with quads to draw
  local tileheight = self.tileheight
  local tilewidth = self.tilewidth
  local tiles = self.tiles
  for layerId=1, #layers do
    local layer = layers[layerId]
    local layertype = layer.type
    if layertype == "tilelayer" then
      local width = layer.width
      local height = layer.height
      local layerdata = layer.data
      local tileIdx = 1
      local posY = 0
      for _=0, height-1 do
        local posX = 0
        for _=0, width-1 do
          local gid = layerdata[tileIdx]
          if gid ~= 0 then
            local tile = gidInfo[gid]
            local tileset = tile.tileset
            batchesPerLayer[layerId][tileset]:add(tile.quad, posX, posY)
          end
          tileIdx = tileIdx + 1
          posX = posX + tilewidth
        end
        posY = posY + tileheight
      end
    end
  end

  return self
end

function Map:draw(tx, ty)
  local batchesPerLayer = self.batchesPerLayer
  for _, batches in pairs(batchesPerLayer) do
    for _, batch in pairs(batches) do
      love.graphics.draw(batch, tx, ty)
    end
  end
end

function Map:initPhysics(world)
  local data = self.data
  local layers = data.layers
  for i=1, #layers do
    local layer = layers[i]
    local layertype = layer.type
    if layertype == "objectgroup" then
      local objects = layer.objects
      for j=1, #objects do
        local object = objects[j]
        local properties = object.properties
        local type = properties.type
        local x = object.x
        local y = object.y
        local w = object.width
        local h = object.height
        local body = love.physics.newBody(world, x+(w/2), y+(h/2), type)
        local shape = love.physics.newRectangleShape(w, h)
        love.physics.newFixture(body, shape)
      end
    end
  end
end

return Map
