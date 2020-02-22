local editor
local menubarheight = 50

-- for tracking the double clicking
local clickcountdown
local clickcountdownlimit = 0.175

function love.load()
    editor = require('editor').new(love.graphics.getWidth(),love.graphics.getHeight()-menubarheight)
end

function love.resize(w,h)
    editor:resize(w, h-menubarheight)
end

function love.draw()
    editor:draw(0,menubarheight)
end

function love.update(dt)
    
    -- for double clicking
    if clickcountdown then
        clickcountdown = clickcountdown - dt
        if clickcountdown < 0 then
            clickcountdown = nil
        end
    end

    editor:update(dt)
end

function love.mousepressed(x, y, b)

    -- determines if we are single or double clicked
    if clickcountdown then editor:mousedoublepressed(x,y - menubarheight,b)
    else editor:mousepressed(x,y - menubarheight,b) end
    
    -- for the double click to work
    if not clickcountdown then clickcountdown = clickcountdownlimit end
end

function love.mousereleased(x,y,b)
    editor:mousereleased(x,y - menubarheight,b)
end

function love.mousemoved(x,y,b)
    editor:mousemoved(x,y - menubarheight,b)
end

function love.keypressed(key, code)
    editor:keypressed(key, code)
end

function love.keyreleased(key, code)
    editor:keyreleased(key, code)
end

function love.filedropped(file)
    local savedData, err = dofile(file:getFilename())
    editor:loadStateFromObj(savedData)
end