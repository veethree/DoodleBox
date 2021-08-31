NAME = "Doodle Box"
VERSION = 0.1
 
-- GLOBALS
lg = love.graphics
fs = love.filesystem
lk = love.keyboard

function love.load()
    -- Loaidng classes
    require("src.class.util")
    require_folder("src/class")

    -- Defining states
    state:define_state("src/state/console.lua", "console")
    state:define_state("src/state/menu.lua", "menu")

    --Config
    default_config = {
        window = {
            width = 1024,
            height = 576,
            fullscreen = false,
            title = NAME.." ["..VERSION.."]"
        },
        project_directory = "Projects"
    }

    config = default_config
    if fs.getInfo("config.lua") then
        config = ttf.load("config.lua")
    else
        save_config()
    end

    --File system
    if not fs.getInfo(config.project_directory) then
        fs.createDirectory(config.project_directory)
    end

    -- Creating window
    love.window.setMode(config.window.width, config.window.height, {fullscreen=config.window.fullscreen})
    love.window.setTitle(config.window.title)

    --Scaling
    scale_x = lg.getWidth() * 0.001
    scale_y = lg.getHeight() * 0.001

    print(scale_x)
    print(scale_y)

    --Loading fonts
    font = {
        regular = lg.newFont("src/font/monogram.ttf", 24 * scale_x)
    }

    state:load("console")
end

function save_config()
    ttf.save(config, "config.lua")
end

function clear_config()
    fs.remove("config.lua")
end

--The following are callback functions
function love.update(dt)
    state:update(dt)
end

function love.draw()
    state:draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.push("quit")
    elseif key == "s" then
        if lk.isDown("lctrl") then
            love.system.openURL("file://"..love.filesystem.getSaveDirectory())
        end
    end
    state:keypressed(key)
end

function love.textinput(t)
    state:textinput(t)
end

function love.keyreleased(key)
    state:keyreleased(key)
end

function love.mousepressed(x, y, key)
    state:mousepressed(x, y, key)
end

function love.mousereleased(x, y, key)
    state:mousereleased(x, y, key)
end

function love.wheelmoved(x, y)
    state:wheelmoved(x, y)
end

function love.quit()
    state:quit()
end

function love.update(dt)
    state:update(dt)
end