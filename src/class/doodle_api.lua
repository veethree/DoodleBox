-- Various functions and variables that are used in projects to make code more compact

--Globals
function update_globals()
    width = lg.getWidth()
    height = lg.getHeight()
    mouseX, mouseY = love.mouse.getPosition()
end

--Shorthands
function color(r, g, b, a)
    if not g then
        g = r
        b = r
        a = 1
    end
    lg.setColor(r, g, b, a)
end

function circle(...)
    lg.circle(...)
end

function rect(...)
    lg.rectangle(...)
end

function poly(...)
    lg.polygon(...)
end

function text(...)
    lg.print(...)
end

function random(...)
    return math.random(...)
end
