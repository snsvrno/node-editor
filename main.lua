local editor
local menubarheight = 50
local filepicker

-- for tracking the double clicking
local clickcountdown
local clickcountdownlimit = 0.175

function love.load()
    editor = require('editor').new(love.graphics.getWidth(),love.graphics.getHeight()-menubarheight)
end

function love.resize(w,h)
    
    if filepicker then filepicker:resize(w,h) end

    editor:resize(w, h-menubarheight)
end

function love.draw()

    -- will draw the filepicker and nothing else.
    if filepicker then filepicker:draw(); return end

    editor:draw(0,menubarheight)
end

function love.update(dt)

    -- will only update the filepicker if the picker is enabled
    if filepicker then 
        -- checks the file variable to see if
        -- the user choses a file.
        if filepicker.file == false then
            -- exits without selecting a file, so we 
            -- kill the filepicker
            filepicker = nil
        elseif filepicker.file then
            -- the chosen file, we then do something.

        end

        if filepicker then
            -- we check it again because we might have 
            -- just destroyed it.
            filepicker:update(dt)
        end

        return
    end
    
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

    if filepicker then return end

    -- determines if we are single or double clicked
    if clickcountdown then editor:mousedoublepressed(x,y - menubarheight,b)
    else editor:mousepressed(x,y - menubarheight,b) end
    
    -- for the double click to work
    if not clickcountdown then clickcountdown = clickcountdownlimit end
end

function love.mousereleased(x,y,b)

    if filepicker then return end

    editor:mousereleased(x,y - menubarheight,b)
end

function love.mousemoved(x,y,b)

    if filepicker then return end

    editor:mousemoved(x,y - menubarheight,b)
end

function love.keypressed(key, code)

    if filepicker then filepicker:keypressed(key, code) end

    if key == "f1" then 
        filepicker = require('filedialog').show{save = true}
        return
    end

    if key == "f2" then 
        filepicker = require('filedialog').show{}
        return
    end
        
    editor:keypressed(key, code)
end

function love.keyreleased(key, code)

    if filepicker then filepicker:keyreleased(key, code) end

    editor:keyreleased(key, code)
end

function love.filedropped(file)
    
    if filepicker then return end

    local savedData, err = dofile(file:getFilename())
    editor:loadStateFromObj(savedData)
end