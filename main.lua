if os.getenv "LOCAL_LUA_DEBUGGER_VSCODE" == "1" then
    local lldebugger = require "lldebugger"
    lldebugger.start()
    local run = love.run
    function love.run(...)
        local debug = lldebugger.call(run, false, ...)
        return function(...) return lldebugger.call(debug, false, ...) end
    end
end

local Character = require "types.Character"
local Context = require "types.Context"
local Weapon = require "types.Weapon"

local chars = {} ---@type Character[]
local weaponTable = {} ---@type Weapon[]
local ctx = Context.new(360, 240, 1, {})

local function reload()
    chars = {}
    love.load()
end

function love.load()
    love.window.setTitle("The Hollow King's Curse")

    local dw, dh = love.window.getDesktopDimensions(1)
    ctx.scale = math.min(math.floor(dw / ctx.w), math.floor(dh / ctx.h))
    if ctx.w * ctx.scale == dw or ctx.h * ctx.scale == dh then
        ctx.scale = ctx.scale - 1
    end
    love.window.setMode(ctx.w * ctx.scale, ctx.h * ctx.scale, {
        fullscreen = false,
        resizable = false,
        vsync = true
    })
    love.graphics.setDefaultFilter("nearest", "nearest")

    local r, g, b = love.math.colorFromBytes(80, 48, 0)
    love.graphics.setBackgroundColor(r, g, b)

    local assetFiles = love.filesystem.getDirectoryItems("assets")
    for _, file in ipairs(assetFiles) do
        local name = file:match("(.+)%.png$")
        if name then
            ctx.imageTable[name] = love.graphics.newImage("assets/" .. file)
        end
    end

    local weaponFiles = love.filesystem.getDirectoryItems("weapons")
    for _, file in ipairs(weaponFiles) do
        local name = file:match("(.+)%.lua$")
        if name then
            local weapon = require("weapons/" .. name)
            weaponTable[name] = Weapon.new(ctx, weapon)
        end
    end

    chars["hero"] = Character.new(
        ctx,
        {
            up = ctx.imageTable["arrowUp"],
            down = ctx.imageTable["arrowDown"],
            left = ctx.imageTable["arrowLeft"],
            right = ctx.imageTable["arrowRight"]
        },
        ctx.w / 2,
        ctx.h / 2,
        60,
        weaponTable["basic"]
    )
end

function love.draw()
    for _, char in pairs(chars) do
        local cw, ch = char.image:getDimensions()
        love.graphics.draw(
            char.image,
            math.floor(char.x) * ctx.scale,
            math.floor(char.y) * ctx.scale,
            0,
            ctx.scale,
            ctx.scale,
            cw / 2,
            ch / 2
        )
        for _, bullet in ipairs(char.weapon.bullets) do
            local pw, ph = char.weapon.image:getDimensions()
            love.graphics.draw(
                char.weapon.image,
                math.floor(bullet.x) * ctx.scale,
                math.floor(bullet.y) * ctx.scale,
                0,
                ctx.scale,
                ctx.scale,
                pw / 2,
                ph / 2
            )
        end
    end
end

function love.update(dt)
    if love.keyboard.isDown("q") then
        love.event.quit()
    end
    if love.keyboard.isDown("r") then
        reload()
    end

    local xMove = 0
    local yMove = 0

    if love.keyboard.isDown("w") then
        yMove = yMove - 1
    end
    if love.keyboard.isDown("s") then
        yMove = yMove + 1
    end
    if love.keyboard.isDown("a") then
        xMove = xMove - 1
    end
    if love.keyboard.isDown("d") then
        xMove = xMove + 1
    end
    chars["hero"]:move(xMove, yMove, 0, 0, dt)

    if love.mouse.isDown(1) then
        local sx = chars["hero"].x
        local sy = chars["hero"].y
        local tx, ty = love.mouse.getPosition()
        tx = math.floor(tx / ctx.scale)
        ty = math.floor(ty / ctx.scale)
        chars["hero"].weapon:fire(sx, sy, tx, ty)
    end

    for _, char in pairs(chars) do
        char.weapon:evaluate(dt)
    end
end
