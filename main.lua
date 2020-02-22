local NODE = require('node')
local CONNECTIONS = { }

local nodes = { }
local clickcountdown
local clickcountdownlimit = 0.175
local workingLine = nil
local connections = { }

function love.load()
    nodes = { }
end

function love.draw()

    love.graphics.setColor(1,1,1)
    for _, connection in pairs(connections) do
        -- the first point, will be either a variable point
        -- or a the generic output
        local ax,ay = 0,0; if connection[1][2] then
            ax = connection[1][1].x + connection[1][2].bx
            ay = connection[1][1].y + connection[1][2].by
        else
            ax = connection[1][1].x + connection[1][1].w
            ay = connection[1][1].y + connection[1][1].idy
        end
        -- can only be the input to a node.
        local bx,by = 1,1; if connection[2][2] then
            bx = connection[2][1].x + connection[2][2].bx
            by = connection[2][1].y + connection[2][2].by
        else
            bx = connection[2][1].x
            by = connection[2][1].y + connection[2][1].idy
        end

        love.graphics.line(ax,ay,bx,by)
    end

    for _, node in pairs(nodes) do
        node:draw()
    end
    

    if workingLine then
        love.graphics.setColor(1,1,1)
        love.graphics.line(workingLine[1], workingLine[2], love.mouse.getX(), love.mouse.getY())
    end
end

function love.update(dt)

    -- for double clicking
    if clickcountdown then
        clickcountdown = clickcountdown - dt
        if clickcountdown < 0 then
            clickcountdown = nil
        end
    end

    for _, node in pairs(nodes) do
        local status = node:update(dt)
        if status then
            if status == NODE.TOGGLESELECTED then
                for _, node2 in pairs(nodes) do
                    if node2 ~= node then node2.selected = false end
                end
            end
        end
    end

end

function love.mousepressed(x,y,b)
    local inANode = false

    if b == 2 and workingLine then
        -- checks if we might want to cancel a dragging link

        workingLine = nil
        return
    end

    -- this is to count for double clicks
    for _, node in pairs(nodes) do
        if clickcountdown then
            node.selected = false
            if node:doublepressed(x,y,b) then inANode = true end
        else
            local result = node:mousepressed(x,y,b) 
            if result then 
                inANode = true
                if type(result) == "table" then
                    if workingLine == nil then
                        -- only the vars can be the start of a drag, if the
                        -- result doesn't have a 4th slot (var) then it is
                        -- the starting node and not a valid dragging link.
                        if result[3].overBall == true then return end

                        workingLine = result

                        -- we can only have one connection per starting point (one path)
                        -- so we need to check all the active connections and remove 
                        -- anything from this same point
                        for i, conn in pairs(connections) do
                            if conn[1][2] == result[4] then
                                table.remove(connections, i)
                                return
                            end
                        end
                    else
                        -- only starting nodes can be the result of a drag link
                        -- so if we have a var in the result, then we have a not
                        -- valid drag link
                        if result[4] ~= nil then return end

                        table.insert(connections, { 
                            { workingLine[3], workingLine[4] }, 
                            { result[3], result[4] }
                        })
                        workingLine = nil
                    end
                end
            end
        end
    end

    if not inANode then
        if clickcountdown then
            table.insert(nodes, NODE.new(x,y))
        end
    end

    if not clickcountdown then clickcountdown = clickcountdownlimit end
end

function love.mousereleased(x,y,b)

    for _, node in pairs(nodes) do
        node:mousereleased(x,y,b)
    end
    
end

function love.mousemoved(x,y)

    for _, node in pairs(nodes) do
        node:mousemoved(x,y,b)
    end
    
end

function love.keypressed(key, code)
    if code == "delete" then
        for index, node in pairs(nodes) do
            if node.selected then 
                table.remove(nodes, index)
                return
            end
        end
    else
        for _, node in pairs(nodes) do
            node:keypressed(key, code)
        end
    end
end

function love.keyreleased(key, code)
    for _, node in pairs(nodes) do
        node:keyreleased(key, code)
    end
end