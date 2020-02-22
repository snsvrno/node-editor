local utf8 = require('utf8')

local NODE = { 
    radius = 10, 
    color = { 0.5, 0.5, 0.5 },
    foreground = { 0,0,0 },
    outlineColor = { 1,1,1 },
    outlineSize = 2,
    selectTimerLimit = 0.5,
    varPadding = 20,
    connectionRadius = 5,
    connectionRadiusColor = { 0.75, 0.75, 0.75 },
    connectionRadiusColorOver = { 1,1,1 },
    plusOverColor = { 1,1,1 },
    varEditColor = { 0.4, 0.4, 0.4 },
    
    padding = 10,
    TOGGLESELECTED = 1546
}
NODE.__index = NODE

function NODE.new(x,y)
    local node = { }

    setmetatable(node, NODE)

    node.title = "node"
    node.vars = {
        { text = "blank" }
    }

    node:_calcSize(x,y)

    return node
end

function NODE:_calcSize(x,y)
    -- recalculates the dimensions of all the elements
    -- so we don't have to do it every cycle

    local font = love.graphics.getFont()
    local fontHeight = font:getHeight()

    local maxVarLength = 0; for _, v in pairs(self.vars) do
        if font:getWidth(v.text) > maxVarLength then maxVarLength = font:getWidth(v.text) end
    end

    self.h = self.padding + fontHeight + self.padding 
           + (fontHeight + self.padding) * #self.vars
           + self.varPadding + self.padding
    self.w = self.varPadding * 2
           + maxVarLength
    self.x = self.x or x - self.w/2
    self.y = self.y or y - self.h/2

    self.idy = self.padding + fontHeight/2

    local starty = self.padding + fontHeight + self.varPadding
    for _, v in pairs(self.vars) do
        v.tx = self.varPadding
        v.tw = font:getWidth(v.text)
        v.ty = starty
        v.th = fontHeight
        v.bx = self.w
        v.by = starty + fontHeight/2
    
        starty = starty + self.padding + fontHeight
    end

    -- determines the '+' size
    self.ax = self.w/2 - font:getWidth("+")/2
    self.ay = self.h - self.padding - font:getHeight()/2
    self.aw = font:getWidth("+")
    self.ah = font:getHeight()
end

function NODE:draw()

    local fontHeight = love.graphics.getFont():getHeight()

    if self.selected then
        love.graphics.setColor(self.outlineColor)
        self:drawShape(
            self.x - self.outlineSize/2, self.y - self.outlineSize/2, 
            self.w + self.outlineSize, self.h + self.outlineSize
        )
    end

    love.graphics.setColor(self.color)
    self:drawShape(self.x, self.y, self.w, self.h)

    -- draws the title
    love.graphics.setColor(self.foreground)
    love.graphics.print(self.title, self.x + self.padding, self.y + self.padding)

    -- draws the input dot
    if self.overBall == true then love.graphics.setColor(self.connectionRadiusColorOver)
    else love.graphics.setColor(self.connectionRadiusColor) end
    love.graphics.circle("fill", self.x, self.y + self.idy, self.connectionRadius)

    -- draws the vars
    local starty = self.y + self.padding + fontHeight + self.varPadding
    for i,v in pairs(self.vars) do
        if i == self.varEdit then
            love.graphics.setColor(self.varEditColor)
            love.graphics.rectangle('fill', 
                self.x + v.tx - self.padding/2, self.y + v.ty - self.padding/2,
                v.tw + self.padding, v.th + self.padding
             )
        end

        love.graphics.setColor(self.foreground)
        love.graphics.print(v.text, self.x + v.tx, self.y + v.ty)

        -- the connection dot
        if v.overBall == true then love.graphics.setColor(self.connectionRadiusColorOver)
        else love.graphics.setColor(self.connectionRadiusColor) end
        love.graphics.circle("fill", self.x + v.bx, self.y + v.by, self.connectionRadius)

        starty = starty + self.padding + fontHeight
    end

    -- draws the '+' at the bottom of the node
    if self.overPlus == true then love.graphics.setColor(self.plusOverColor)
    else love.graphics.setColor(self.foreground) end
    love.graphics.print("+", self.x + self.ax, self.y + self.ay)

end

function NODE:drawShape(x,y,w,h)
    love.graphics.rectangle("fill", x + self.radius, y, w - 2*self.radius, h)
    love.graphics.rectangle("fill", x, y + self.radius, w, h - 2*self.radius)
    love.graphics.circle("fill", x + self.radius, y + self.radius, self.radius)
    love.graphics.circle("fill", x + w - self.radius, y + self.radius, self.radius)
    love.graphics.circle("fill", x + self.radius, y + h - self.radius, self.radius)
    love.graphics.circle("fill", x + w - self.radius, y + h - self.radius, self.radius)
end

function NODE:update(dt) 


    if self.grabbed then
        self.x = self.ox - self.mx + love.mouse.getX()
        self.y = self.oy - self.my + love.mouse.getY()
    end
end

function NODE:mousemoved(x,y)
    -- checks if we are over any of the items (+ their connections)
    for _, v in pairs(self.vars) do
        if v.bx + self.x - self.connectionRadius <= x and x <= v.bx + self.x + self.connectionRadius
        and v.by + self.y - self.connectionRadius <= y and y <= v.by + self.y + self.connectionRadius then
            v.overBall = true
        else
            v.overBall = false
        end
    end

    -- checks if we are over the input dot
    if self.x - self.connectionRadius <= x and x <= self.x + self.connectionRadius
    and self.y + self.idy - self.connectionRadius <= y and y <= self.y + self.idy + self.connectionRadius then
        self.overBall = true
    else
        self.overBall = false
    end

    -- checks if we are over the plus at the bottom
    if self.x <= x and x <= self.x + self.w
    and self.y + self.ay <= y and y <= self.y + self.ay + self.ah then
        self.overPlus = true
    else
        self.overPlus = false
    end
end

function NODE:mousepressed(x,y,b)
    if b == 1 then

        -- first we check if we are over a dot.
        local checkdrag = true; if self.overBall then
            -- over input dot.
            checkdrag = false
            return {
                self.x, self.y + self.idy, self
            }
        else
            for i,v in pairs(self.vars) do
                if v.overBall then 
                    checkdrag = false
                    return {
                        self.x + v.bx, self.y + v.by, self, v
                    }
                end
            end
        end

        if self.x <= x and x <= self.x + self.w 
        and self.y <= y and y <= self.y + self.h 
        and checkdrag then
            -- doing the grab stuff
            self.grabbed = true
            self.ox = self.x
            self.oy = self.y
            self.mx = x
            self.my = y

            -- checking other options
            if self.overPlus then
                -- if we are over plus then we want to add another option
                self:addVar()
            end

            return true
        end
    end
end

function NODE:doublepressed(x,y,b)
    -- double click command

    if b == 1 then
        -- checks if the mouse is inside the node box.
        if self.x <= x and x <= self.x + self.w 
        and self.y <= y and y <= self.y + self.h then

            -- check if we are over a var field (the text)
            for i, v in pairs(self.vars) do
                if self.x + v.tx <= x and x <= self.x + v.tx + v.tw
                and self.y + v.ty <= y and y <= self.y + v.ty + v.th then
                    self.varEdit = i
                    self.keyboardshift = 0
                    return true
                end
            end

            self.varEdit = nil
            self.selected = true

            -- ignore all other things because we can only edit
            -- one text field at once.
            return true
        end
    end
end

function NODE:mousereleased(x,y,b)
    
    -- checks if the mouse is inside then node
    if self.x <= x and x <= self.x + self.w 
    and self.y <= y and y <= self.y + self.h then
        
        -- if the mouse was released in the node area then we should make sure
        -- that we unset the grab
        self.grabbed = false
    end
end

function NODE:addVar()
    -- adds a new variable to the set, a new line
    -- item as "blank"

    local name = "blank"
    local start = 0
    local alreadyUsed = true

    while alreadyUsed do
        start = start + 1
        name = "blank " .. tostring(start)

        alreadyUsed = false
        for _,v in pairs(self.vars) do
            if v.text == name then
                alreadyUsed = true
            end
        end
    end

    table.insert(self.vars, { text = name })

    self:_calcSize()
end

function NODE:keypressed(key, code)
    if self.varEdit then

        local i = self.varEdit
        local numberCode = string.byte(code)

        if code == "backspace" then
            if #self.vars[i].text > 0 then
                self.vars[i].text = self.vars[i].text:sub(i,#self.vars[i].text-1)
                self:_calcSize()
            end

        elseif code == "return" then
            self.varEdit = nil
            table.sort(self.vars, function(a,b) return a.text < b.text end)
            self:_calcSize()

        elseif code == "lshift" or code == "rshift" then
            self.keyboardshift = self.keyboardshift + 1
        
        elseif 97 <= numberCode and numberCode <= 122 then
            -- we are in the letter range, so we should look
            -- for a shift enabler
            if self.keyboardshift > 0 then
                -- a capital letter
                code = utf8.char(numberCode - 32)
            end

            self.vars[i].text = self.vars[i].text .. code
            self:_calcSize()

        elseif #code == 1 then
            self.vars[i].text = self.vars[i].text .. code
            self:_calcSize()
        end

    end
end

function NODE:keyreleased(key, code)
    if self.varEdit then
        if code == "lshift" or code == "rshift" then
            self.keyboardshift  = self.keyboardshift - 1
        end
    end
end 

return NODE