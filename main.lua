local NODE = require('node')

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
                        local _, oldindex = getConnection((result[4] or result[3]).id)
                        -- the (result[4] or result[3]) is because of the dumb way i did this,
                        -- probably have to refactor it later but it works now.
                        if oldindex then
                            table.remove(connections, oldindex)
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
    if code == "s" then save() return end
    
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

function getConnection(id)
    for index, conn in pairs(connections) do
        local obj = conn[1][1]; if conn[1][2] then obj = conn[1][2] end
        if obj.id == id then
            if conn[2][2] then return conn[2][2].id, index
            else return conn[2][1].id, index end
        end
    end
end

local function translateVars(node)
    local string = "{ "

    for _, var in pairs(node.vars) do
        string = string .. "{ "
        string = string .. "id = \"" .. var.id .. "\", "
        string = string .. "text = \"" .. var.text .. "\", "
        local connection = getConnection(var.id); if connection then
            string = string .. "conn = \"" .. connection .. "\", "
        end 
        string = string .. " },"
    end

    return string .. " }"
end

local function translateNode(node)
    local string = "{ "

    string = string .. "id = \"" .. node.id .. "\", "
    string = string .. "x = \"" .. (node.x + node.w/2) .. "\", "
    string = string .. "y = \"" .. (node.y + node.h/2) .. "\", "
    string = string .. "title = \"" .. node.title .. "\", "
    local connection = getConnection(node.id); if connection then
        string = string .. "conn = \"" .. connection .. "\", "
    end 
    string = string .. "vars = " .. translateVars(node) .. ", "

    return string .. " }"
end

function save()
    local file = love.filesystem.newFile("saved.nodenet.lua","w")
    
    local string = "return {\n"

    string = string .. "  nodes = {\n"
    for i, node in pairs(nodes) do
        local nodeText = translateNode(node)

        string = string .. "    " .. nodeText .. ",\n"
    end
    string = string .. "  }"

    string = string .. "}"
    file:write(string)
    file:close()

    return
end

local function getConnectionSetFromNodes(id)
    for _, n in pairs(nodes) do
        -- first checks if this is a node
        if n.id == id then
            return { n }
        end

        for _, v in pairs(n.vars or { }) do
            if v.id == id then
                return { n, v }
            end
        end
    end

    assert(false)
end

function load(filename)
    local savedData, err = dofile(filename)

    nodes = { }
    connections = { }

    -- loads the nodes
    for _, n in pairs(savedData.nodes) do
        table.insert(nodes, NODE.fromSaved(n))
    end

    print("loaded " .. tostring(#nodes) .. " nodes")

    -- creates the connections, first owner then element (if any)
    for _, n in pairs(savedData.nodes) do
        -- check the main node
        if n.conn then
            table.insert(connections, {
                getConnectionSetFromNodes(n.id),
                getConnectionSetFromNodes(n.conn)
            })
        end

        -- check all the vars
        for _, v in pairs(n.vars or { }) do
            if v.conn then 
                table.insert(connections, {
                    getConnectionSetFromNodes(v.id),
                    getConnectionSetFromNodes(v.conn)
                })
            end
        end
    end

end

function love.filedropped(file)
    load(file:getFilename())
end