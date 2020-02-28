local lfs
local utf8 = require('utf8')

local FILEPICKER = {
    backgroundColor = { 0.5, 0.5, 0.5 },
    textPadding = 4,
    font = love.graphics.newFont(12),
    textBoxColor = { 0.1, 0.1, 0.1 },
    textColor = { 1,1,1 },
    textColorSelected = { 0.2, 0.2, 0.2 },
    itemBackground1 = { 0.2, 0.2, 0.2 },
    itemBackground2 = { 0.4, 0.4, 0.4 },
    itemBackgroundSelected = { 0.8, 0.8, 0.8 },
    titleForeground = { 1,1,1 },
    titleBackground = { 0.2, 0.2, 0.2 },
    NEWFILETEXT = "{make a new file}"
}
FILEPICKER.__index = FILEPICKER

function FILEPICKER.show(options)
    local options = options or { }

    local picker = { }
    setmetatable(picker, FILEPICKER)

    local error; do
        lfs, error = loadfile('lfs')
    end

    picker.choices = { }
    picker.selectedChoice = 1

    picker.fileName = ""
    picker.fileExtension = ".nodes.lua"
    picker.keyboardshift = 0
    picker.canCreate = options.save

    picker:queryChoices("")

    return picker
end

function FILEPICKER:draw()

    local oldFont = love.graphics.getFont()
    love.graphics.setFont(self.font)

    local lineHeight = self.font:getHeight()

    local drawStart = 0
    do -- makes the tilte
        local text; if self.windowTitle then text = self.windowTitle 
        elseif self.canCreate then text = "save file.." 
        else text = "load file.." end
        
        love.graphics.setColor(self.titleBackground)
        love.graphics.rectangle('fill',0,drawStart, love.graphics.getWidth(), lineHeight + self.textPadding * 2)
        
        love.graphics.setColor(self.titleForeground)
        love.graphics.print(text,self.textPadding, self.textPadding + drawStart)
        
        drawStart = drawStart + self.textPadding * 2 + lineHeight
    end

    -- draws the part that shows the file.
    if self.canCreate then
        love.graphics.setColor(self.textBoxColor)
        love.graphics.rectangle("fill", 0, drawStart, love.graphics.getWidth(), lineHeight + self.textPadding * 2)
        love.graphics.setColor(self.textColor)
        love.graphics.rectangle("line", 0, drawStart, love.graphics.getWidth(), lineHeight + self.textPadding * 2)
    
        love.graphics.print(self.fileName .. self.fileExtension, self.textPadding, self.textPadding + drawStart)
        drawStart = drawStart + lineHeight + self.textPadding * 2
    end

    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, drawStart, love.graphics.getWidth(), love.graphics.getHeight() - drawStart)
    
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(oldFont)

    -- draws the items
    local starty = drawStart + self.textPadding
    for i, item in pairs(self.choices) do
        
        -- gets the right background color. 
        if i == self.selectedChoice then love.graphics.setColor(self.itemBackgroundSelected)
        elseif i % 2 == 1 then love.graphics.setColor(self.itemBackground1)
        else love.graphics.setColor(self.itemBackground2) end
        love.graphics.rectangle('fill', 0, starty - self.textPadding, love.graphics.getWidth(), self.textPadding * 2 + lineHeight)
        
        if i == self.selectedChoice then love.graphics.setColor(self.textColorSelected)
        else love.graphics.setColor(self.textColor) end
        love.graphics.print(item.name, self.textPadding, starty)
        starty = starty + self.textPadding * 2 + lineHeight
    end

    -- draws the outline around the box.
    love.graphics.setColor(self.textColor)
    love.graphics.rectangle("line", 0, drawStart, love.graphics.getWidth(), love.graphics.getHeight() - drawStart)

    return
end

function FILEPICKER:update(dt)

end

function FILEPICKER:queryChoices(path)
    self.selectedChoice = 1
    self.choices = { }

    if lfs then
        -- gets the correct directory listing using lua file system

    else
        -- we only get the saved folder listing, and can't navigate
        -- to other folders

        files = love.filesystem.getDirectoryItems(path)
        for _, file in pairs(files) do
            local id = love.filesystem.getInfo(path .. "/" .. file, "file")
            if id == true then id = "file" else id = "folder" end
            if file:sub(#file - #self.fileExtension + 1, #file) == self.fileExtension then
                table.insert(self.choices, {
                    name = file,
                    icon = id
                })
            end
        end

        table.sort(self.choices, function(a,b) return a.name < b.name end)
    end

    -- option that the user will select to make a new file (not override any)
    if self.canCreate then table.insert(self.choices, 1, { 
        name = self.NEWFILETEXT
    }) end

    -- if we don't have lfs then we can't look at any other folders
    if lfs then table.insert(self.choices, 1, {  name = ".." }) end

end

function FILEPICKER:keypressed(key, code)

    -- does normal functions.
    if key == "escape" then
        self.file = false
    elseif key == "up" then
        self.selectedChoice = self.selectedChoice - 1
        if self.selectedChoice < 1 then self.selectedChoice = #self.choices end
    elseif key == "down" then
        self.selectedChoice = self.selectedChoice + 1
        if self.selectedChoice > #self.choices then self.selectedChoice = 1 end
    end

    -- no more normal functions, now do normal typing input.
    if self.canCreate then
        local numberCode = string.byte(code); if #code > 1 then numberCode = 0 end

        if code == "backspace" then
            if #self.fileName > 0 then
                self.fileName = self.fileName:sub(1,#self.fileName - 1)
            end

        elseif code == "lshift" or code == "rshift" then
            self.keyboardshift = self.keyboardshift + 1
        
        elseif 97 <= numberCode and numberCode <= 122 then
            -- we are in the letter range, so we should look
            -- for a shift enabler
            if self.keyboardshift > 0 then
                -- a capital letter
                code = utf8.char(numberCode - 32)
            end

            self.fileName = self.fileName .. code

        elseif #code == 1 then
            self.fileName = self.fileName .. code
        end
    end

end

function FILEPICKER:keyreleased(key, code)

    if code == "lshift" or code == "rshift" then
        self.keyboardshift  = self.keyboardshift - 1
    end
end

return FILEPICKER