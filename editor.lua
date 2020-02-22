local EDITOR = { 
    background = { 0.3, 0.3, 0.3},
    viewportBorder = {1,1,1},
    lines = {
        standard = { 1,1,1 },
    },
}
EDITOR.__index = EDITOR

local NODE = require('node')

function EDITOR.new(w,h)
    local editor = { }

    setmetatable(editor, EDITOR)

    editor.nodes = { }
    editor.connections = { }

    editor.w = w
    editor.h = h

    -- mouse coordinates, because these will be adjusted
    editor.mx = 0
    editor.my = 0

    -- viewport camera options
    editor.ox = 0
    editor.oy = 0

    editor.canvas = love.graphics.newCanvas(w,h)

    -- for drawing the line while the user
    -- is connecting it to the nodes
    editor.workingLine = nil

    editor:init()

    return editor
end

function EDITOR:init()
    self.nodes = { }
    self.connections = { }
    self.workingLine = nil
end

function EDITOR:drawBackground()
    local vx = 0 - self.ox
    local vy = 0 - self.oy
    local vw = self.w
    local vh = self.h
    
    love.graphics.setColor(self.background)
    love.graphics.rectangle("fill", vx - 10, vy -10, vw + 20, vh + 20)
end

function EDITOR:draw(x,y)
    -- the drawing parameters are the viewports current area
    
    self.canvas:renderTo(function()
        love.graphics.clear()

        -- locks the current transformations
        love.graphics.push()
        love.graphics.translate(self.ox, self.oy)

        -- draws the background
        self:drawBackground()
        love.graphics.setColor(1,1,1)

        -- draws all the saved connections
        for _, conn in pairs(self.connections) do
            -- the first point, which is always an output
            local ax, ay = 0,0; if conn[1][2] then
                ax = conn[1][1].x + conn[1][2].bx
                ay = conn[1][1].y + conn[1][2].by
            else
                ax = conn[1][1].x + conn[1][1].w
                ay = conn[1][1].y + conn[1][1].idy
            end

            -- can only be the input to a node.
            local bx,by = 1,1; if conn[2][2] then
                bx = conn[2][1].x + conn[2][2].bx
                by = conn[2][1].y + conn[2][2].by
            else
                bx = conn[2][1].x
                by = conn[2][1].y + conn[2][1].idy
            end
    
            love.graphics.setColor(self.lines.standard)
            love.graphics.line(ax,ay,bx,by)
        end

        -- draws the nodes
        for _, n in pairs(self.nodes) do n:draw() end

        -- draws the active connection
        if self.workingLine then
            love.graphics.setColor(self.lines.standard)
            love.graphics.line(self.workingLine[1], self.workingLine[2], self.mx, self.my)
        end

        -- reverts to the older transformations
        love.graphics.pop()
    end)

    -- draws the canvas
    love.graphics.setColor(1,1,1)
    love.graphics.draw(self.canvas, x, y)
    -- draws the outline
    love.graphics.setColor(self.viewportBorder)
    love.graphics.rectangle("line",x,y, self.w, self.h)
end

function EDITOR:update(dt)
    
    -- for deselecting the nodes so we don't have more than
    -- one node selected at once.
    for _, n in pairs(self.nodes) do
        local status = n:update(dt, self.mx, self.my)
        if status then if status == NODE.TOGGLESELECTED then
            for _, n2 in pairs(self.nodes) do
                if n2 ~= n then n2.selected = false end
            end
        end end
    end

    -- does dragging if we were dragging the viewport around
    if self.dragging then
        self.ox = self.dragging.ox - self.dragging.mx + self.mox
        self.oy = self.dragging.oy - self.dragging.my + self.moy
    end

    return
end

function EDITOR:resize(w,h)
    self.w = w
    self.h = h
    self.canvas = love.graphics.newCanvas(w,h)
end

function EDITOR:mousepressed(x,y,b)
    -- for single click
    ox,oy = x,y -- non translated mouse
    x,y = self:translateMouse(x,y)
    
    local inANode = false

    if b == 2 and self.workingLine then
        -- checks if we might want to cancel a dragging link
        workingLine = nil; return
    elseif b == 2 then
        -- if we have a right click and we're not drawing then
        -- we want to drag the window around
        self.dragging = {
            ox = self.ox,
            oy = self.oy,
            mx = ox,
            my = oy,
        }
    end

    for _,n in pairs(self.nodes) do
        local result = n:mousepressed(x,y,b); if result then
            inANode = true
            if type(result) == "table" then
                if self.workingLine == nil then
                    -- only the vars can be the start of a drag, if the
                    -- result doesn't have a 4th slot (var) then it is
                    -- the starting node and not a valid dragging link.
                    if result[3].overBall == true then return end

                    self.workingLine = result

                    -- we can only have one connection per starting point (one path)
                    -- so we need to check all the active connections and remove 
                    -- anything from this same point
                    local _, oldindex = self:getConnection((result[4] or result[3]).id)
                    -- the (result[4] or result[3]) is because of the dumb way i did this,
                    -- probably have to refactor it later but it works now.
                    if oldindex then
                        table.remove(self.connections, oldindex)
                    end
                else
                    -- only starting nodes can be the result of a drag link
                    -- so if we have a var in the result, then we have a not
                    -- valid drag link
                    if result[4] ~= nil then return end

                    table.insert(self.connections, { 
                        { self.workingLine[3], self.workingLine[4] }, 
                        { result[3], result[4] }
                    })
                    self.workingLine = nil
                end
            end
        end
    end

end

function EDITOR:mousedoublepressed(x,y,b)
    -- for double click
    x,y = self:translateMouse(x,y)
    
    local inANode = false

    for _,n in pairs(self.nodes) do
        n.selected = false
        if n:mousedoublepressed(x,y,b) then inANode = true end
    end

    if not inANode then table.insert(self.nodes, NODE.new(x,y)) end
end

function EDITOR:mousereleased(x,y,b)
    x,y = self:translateMouse(x,y)

    for _, n in pairs(self.nodes) do
        n:mousereleased(x,y,b)
    end

    if b == 2 then
        -- stops dragging if we were dragging the window.
        self.dragging = nil
    end
end

function EDITOR:translateMouse(x,y)

    -- modify the inputs so they match the transformations
    x = x - self.ox
    y = y - self.oy

    return x,y
end

function EDITOR:mousemoved(x,y,b)
    self.mox, self.moy = x,y -- untranslated
    x,y = self:translateMouse(x,y)
    self.mx, self.my = x, y

    for _, n in pairs(self.nodes) do
        n:mousemoved(x,y,b)
    end
end

function EDITOR:keypressed(key, code)
    
    if code == "delete" then
        -- delete all the selected nodes
        for index, n in pairs(self.nodes) do
            if n.selected then 
                table.remove(self.nodes, index); return
            end
        end
    else
        -- othewise we pass through to the nodes
        for _, n in pairs(self. nodes) do
            n:keypressed(key, code)
        end
    end

    if key == "left" then self.ox = self.ox + 100
    elseif key == "right" then self.ox = self.ox - 100 end
end

function EDITOR:keyreleased(key, code)
    for _, n in pairs(self.nodes) do
        n:keyreleased(key, code)
    end
end

-- saving stuff


function EDITOR:getConnection(id)
    for index, conn in pairs(self.connections) do
        local obj = conn[1][1]; if conn[1][2] then obj = conn[1][2] end
        if obj.id == id then
            if conn[2][2] then return conn[2][2].id, index
            else return conn[2][1].id, index end
        end
    end
end

function EDITOR:translateVars(node)
    local string = "{ "

    for _, var in pairs(self.node.vars) do
        string = string .. "{ "
        string = string .. "id = \"" .. var.id .. "\", "
        string = string .. "text = \"" .. var.text .. "\", "
        local conn = self:getConnection(var.id); if conn then
            string = string .. "conn = \"" .. conn .. "\", "
        end 
        string = string .. " },"
    end

    return string .. " }"
end

function EDITOR:translateNode(node)
    local string = "{ "

    string = string .. "id = \"" .. node.id .. "\", "
    string = string .. "x = \"" .. (node.x + node.w/2) .. "\", "
    string = string .. "y = \"" .. (node.y + node.h/2) .. "\", "
    string = string .. "title = \"" .. node.title .. "\", "
    local conn = self:getConnection(node.id); if conn then
        string = string .. "conn = \"" .. conn .. "\", "
    end 
    string = string .. "vars = " .. self:translateVars(node) .. ", "

    return string .. " }"
end

function EDITOR:getConnectionSetFromNodes(id)
    -- gets the connection set information from the 
    -- nodes list using the id, for loading from saved state

    for _, n in pairs(self.nodes) do
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

function EDITOR:saveStateToString()
    local string = "return {\n"

    string = string .. "  nodes = {\n"
    for i, node in pairs(self.nodes) do
        local nodeText = self:translateNode(node)

        string = string .. "    " .. nodeText .. ",\n"
    end
    string = string .. "  }"

    string = string .. "}"

    return string
end

function EDITOR:loadStateFromObj(savedData)

    -- resets the editor to the inital state
    self:init()

    -- loads the nodes
    for _, n in pairs(savedData.nodes) do
        table.insert(self.nodes, NODE.fromSaved(n))
    end

    -- creates the connections, first owner then element (if any)
    for _, n in pairs(savedData.nodes) do
        -- check the main node
        if n.conn then
            table.insert(self.connections, {
                self:getConnectionSetFromNodes(n.id),
                self:getConnectionSetFromNodes(n.conn)
            })
        end

        -- check all the vars
        for _, v in pairs(n.vars or { }) do
            if v.conn then 
                table.insert(self.connections, {
                    self:getConnectionSetFromNodes(v.id),
                    self:getConnectionSetFromNodes(v.conn)
                })
            end
        end
    end
end

return EDITOR