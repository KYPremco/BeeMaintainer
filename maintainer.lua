local component = require("component")
local filesystem = require("filesystem")
local initialize = require('setup')
local console = require('console')
local event = require("event")

local TIMER_INTERVAL_IN_SECONDS = 600

local MINIMUM_QUANTITY = 2000000
local BATCH_SIZE = 25000

local FLUID_MINIMUM_QUANTITY = 4000000
local FLUID_BATCH_SIZE = 250000

local RED_COLOR = 0xFF0000
local GREEN_COLOR = 0x00FF00
local ORANGE_COLOR = 0xFFA500

--- @type me_controller
local mainNetwork
--- @type me_controller
local subNetwork

local outputs
local outputToCraftables

local gpu = component.gpu
local w = gpu.getResolution()

mainNetwork, subNetwork, outputs, outputToCraftables = initialize()

function realtime()
    local filename = os.tmpname()
    local file = filesystem.open(filename, "a")
    if file then
        file:close()
        local timestamp = filesystem.lastModified(filename) / 1000
        filesystem.remove(filename)
        return timestamp
    else
        return 0
    end
end

function maintain()
    console.clear()
    print()
    print(string.rep("-", w))
    print("Maintainer requested at:     " .. os.date("%d-%m-%Y %H:%M:%S", realtime()))
    print(string.rep("-", w))
    
    local subNetworkItems = mapSubNetworkItems()
    
    for itemLabel in pairs(getItemsBelowMinimumQuantity()) do
        if subNetworkItems[outputs[itemLabel]] == nil then
            if (itemLabel:sub(1, 7) == "drop of") then
                requestItem(itemLabel, outputToCraftables[itemLabel], FLUID_BATCH_SIZE)
            else
                requestItem(itemLabel, outputToCraftables[itemLabel], BATCH_SIZE)
            end
        else
            console.writeItem(itemLabel, "Skipped", ORANGE_COLOR)
        end
    end
end

function requestItem(itemLabel, craftable, quantity)
    local request = craftable.request(quantity)

    if request.isDone() then
        console.writeItem(itemLabel, quantity, ORANGE_COLOR)
    elseif request.hasFailed() then
        if quantity > 2000 then
            requestItem(itemLabel, craftable, math.floor(quantity / 4))
        else
            console.writeItem(itemLabel, quantity, RED_COLOR)
        end
    else
        console.writeItem(itemLabel, quantity, ORANGE_COLOR)
    end
end

function mapSubNetworkItems()
    local items = {}
    
    for item in subNetwork.allItems() do
        items[item.label] = true
    end
    
    return items
end

function getItemsBelowMinimumQuantity()
    local itemsBelowMinimumQuantity = {}
    
    for item in mainNetwork.allItems() do
        if not item.isCraftable then
            goto continue
        end

        if itemQuantityIsMaintained(item) then
            console.writeItem(item.label, "Ready", GREEN_COLOR)
            goto continue
        end

        itemsBelowMinimumQuantity[item.label] = true

        ::continue::
    end
    
    return itemsBelowMinimumQuantity
end

function itemQuantityIsMaintained(item)
    if (item.label:sub(1, 7) == "drop of") then
        if item.size >= FLUID_MINIMUM_QUANTITY then
            return true
        end
    else
        if item.size >= MINIMUM_QUANTITY then
            return true
        end
    end
    
    return false
end

console.clear()
print("Registered outputs, starting in 5 seconds...")
for outputLabel, input in pairs(outputs) do
    console.writeItem(outputLabel  .. "->" .. input, nil, 0xFFFFFF)
end
os.sleep(5)

maintain()

local maintainerEvent = event.timer(TIMER_INTERVAL_IN_SECONDS, maintain, math.huge)

while true do
    local name = event.pull()  -- waits indefinitely
    if name == "interrupted" then
        event.cancel(maintainerEvent)
        break
    end
end