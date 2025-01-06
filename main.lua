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
local Utility = require "types.Utility"
local Vector = require "types.Vector"
local Weapon = require "types.Weapon"

local context = Context.new(320, 180, 1)

local function reload()
    love.load()
end

local function evalCombat(dt)
    for id, character in pairs(context.characterTable) do
        if character.health <= 0 then
            context.audioTable["enemyDead"]:setPitch(1)
            context.audioTable["enemyDead"]:setPitch(1 + love.math.random(-1, 1) / 10)
            context.audioTable["enemyDead"]:play()
            context.characterTable[id] = nil
        end
        character.weapon:evaluate(dt)
    end

    if context.characterTable["enemy"] == nil then
        context.characterTable["enemy"] = Character.new(
            context,
            {
                down = context.imageTable["diamond"],
            },
            Vector.new(math.random(0, context.width), math.random(0, context.height)),
            60,
            context.weaponTable["basic"]
        )
    end

    for i, bullet in ipairs(context.bulletTable) do
        local collision = Utility.checkCollision(
            bullet.position,
            Vector.new(bullet.image:getDimensions()),
            context.characterTable["enemy"].position,
            Vector.new(context.characterTable["enemy"].image:getDimensions()) / 2
        )
        if collision then
            context.characterTable["enemy"].health = context.characterTable["enemy"].health - 10
            bullet.destroy = true
        end
        if bullet.destroy then
            table.remove(context.bulletTable, i)
            goto continue
        end
        bullet.eval(bullet, dt)
        bullet.lifetime = bullet.lifetime + dt
        ::continue::
    end
end

function love.load()
    love.window.setTitle("The Hollow King's Curse")

    local desktopWidth, desktopHeight = love.window.getDesktopDimensions(1)
    context.scale = math.min(math.floor(desktopWidth / context.width), math.floor(desktopHeight / context.height))
    if context.width * context.scale == desktopWidth or context.height * context.scale == desktopHeight then
        context.scale = context.scale - 1
    end
    love.window.setMode(context.width * context.scale, context.height * context.scale, {
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
            context.imageTable[name] = love.graphics.newImage("assets/" .. file)
        end
    end

    local weaponFiles = love.filesystem.getDirectoryItems("weapons")
    for _, file in ipairs(weaponFiles) do
        local name = file:match("(.+)%.lua$")
        if name then
            local weapon = require("weapons/" .. name)
            context.weaponTable[name] = Weapon.new(context, weapon)
        end
    end

    local audioFiles = love.filesystem.getDirectoryItems("assets")
    for _, file in ipairs(audioFiles) do
        local name = file:match("(.+)%.wav$")
        if name then
            context.audioTable[name] = love.audio.newSource("assets/" .. file, "static")
        end
    end

    context.characterTable["enemy"] = Character.new(
        context,
        {
            down = context.imageTable["diamond"],
        },
        Vector.new(math.random(0, context.width), math.random(0, context.height)),
        60,
        context.weaponTable["basic"]
    )

    context.characterTable["hero"] = Character.new(
        context,
        {
            up = context.imageTable["arrowUp"],
            down = context.imageTable["arrowDown"],
            left = context.imageTable["arrowLeft"],
            right = context.imageTable["arrowRight"]
        },
        Vector.new(context.width / 2, context.height / 2),
        60,
        context.weaponTable["basic"]
    )
end

function love.draw()
    for _, character in pairs(context.characterTable) do
        local characterWidth, characterHeight = character.image:getDimensions()
        love.graphics.draw(
            character.image,
            math.floor(character.position.x) * context.scale,
            math.floor(character.position.y) * context.scale,
            0,
            context.scale,
            context.scale,
            characterWidth / 2,
            characterHeight / 2
        )

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle(
            "fill",
            math.floor(character.position.x - (characterWidth / 2) - 1) * context.scale,
            math.floor(character.position.y - (characterHeight / 2 + 1) + characterHeight + 2) * context.scale,
            (characterWidth + 2) * context.scale,
            3 * context.scale
        )
        love.graphics.setColor(1/2, 1/2, 1/2)
        love.graphics.rectangle(
            "fill",
            math.floor(character.position.x - (characterWidth / 2)) * context.scale,
            math.floor(character.position.y - (characterHeight / 2) + characterHeight + 2) * context.scale,
            characterWidth * context.scale,
            context.scale
        )
        local barWidth, percent = Utility.map(0, character.maxHealth, 0, characterWidth, character.health)
        local r = -percent + 1
        local g = percent
        local a = math.min(1 / r, 1 / g)
        r = r * a
        g = g * a
        love.graphics.setColor(r, g, 0)
        love.graphics.rectangle(
            "fill",
            math.floor(character.position.x - (characterWidth / 2)) * context.scale,
            math.floor(character.position.y - (characterHeight / 2) + characterHeight + 2) * context.scale,
            math.floor(barWidth) * context.scale,
            context.scale
        )
        love.graphics.setColor(1, 1, 1)
    end
    for _, bullet in ipairs(context.bulletTable) do
        local bulletWidth, bulletHeight = bullet.image:getDimensions()
        love.graphics.draw(
            bullet.image,
            math.floor(bullet.position.x) * context.scale,
            math.floor(bullet.position.y) * context.scale,
            0,
            context.scale,
            context.scale,
            bulletWidth / 2,
            bulletHeight / 2
        )
    end
end

function love.update(dt)
    if love.keyboard.isDown("q") then
        love.event.quit()
    end
    if love.keyboard.isDown("r") then
        reload()
    end

    local move = Vector.new()
    if love.keyboard.isDown("w") then
        move.y = move.y - 1
    end
    if love.keyboard.isDown("s") then
        move.y = move.y + 1
    end
    if love.keyboard.isDown("a") then
        move.x = move.x - 1
    end
    if love.keyboard.isDown("d") then
        move.x = move.x + 1
    end
    context.characterTable["hero"]:move(move, Vector.new(), dt)

    if love.mouse.isDown(1) then
        local start = Vector.new(context.characterTable["hero"].position.x, context.characterTable["hero"].position.y)
        local target = Vector.new(love.mouse.getPosition()) / context.scale
        context.characterTable["hero"].weapon:fire(start, target)
    end

    evalCombat(dt)
end

love.keypressed = function(key)
    if key == "1" then
        context.characterTable["hero"].weapon = context.weaponTable["basic"]
    end
    if key == "2" then
        context.characterTable["hero"].weapon = context.weaponTable["accelerate"]
    end
    if key == "3" then
        context.characterTable["hero"].weapon = context.weaponTable["10Burst3Fan"]
    end
end