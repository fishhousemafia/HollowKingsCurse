math.randomseed(os.clock())
for x=-32,32 do
  for y=-32,32 do
    local r = math.random()
    local g = math.random()
    local b = math.random()
    print(string.format("%d,%d,16,16,%f,%f,%f,", x*16, y*16, r, g, b))
  end
end
