local component = require("component")
local term = require("term")

local gpu = component.gpu

local w = gpu.getResolution()

local columns = 3
local colWidth = math.floor(w / columns)

local y = 1
local col = 1

local console = {}

function console.writeItem(text, quantity, color)
    gpu.setForeground(color)

    local trimmed = text:sub(1, 40)
    local quantityLabel = quantity or ""
    local formattedText = trimmed .. string.rep(".", 40 - #trimmed) .. quantityLabel

    local startX = (col - 1) * colWidth + math.floor(colWidth/2) - 23

    gpu.set(startX, y, formattedText)

    -- draw divider
    if col < columns then
        gpu.setForeground(0xFFFFFF)
        gpu.set(col * colWidth - 1, y, "||")
    end

    -- move to next column
    col = col + 1

    -- wrap to next line
    if col > columns then
        col = 1
        y = y + 1
    end
end

function console.clear()
    term.clear()
    y = 5
    col = 1
end

return console