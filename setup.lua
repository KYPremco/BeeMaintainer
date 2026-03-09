local component = require("component")

function initialize()
    local mainNetwork, subNetwork = identifyMeControllers()

    local outputs = registerOutputs()
    
    local outputToCraftables = mapOutputToCraftables(mainNetwork, outputs)
    
    return mainNetwork, subNetwork, outputs, outputToCraftables
end

function mapOutputToCraftables(mainNetwork, outputs)
    local outputToCraftables = {}
    
    local craftables = mainNetwork.getCraftables()

    for _, craftable in pairs(craftables) do
        outputToCraftables[craftable.getItemStack().label] = craftable

        if craftable.getItemStack().name == "minecraft:paper" then
            outputs[craftable.getItemStack().label] = craftable.getItemStack().label
        end
    end
    
    return outputToCraftables
end

function identifyMeControllers()
    --- @type me_controller
    local mainNetwork = nil
    --- @type me_controller
    local subNetwork = nil
    
    local counter = 0

    for address, _ in component.list("me_controller") do
        counter = counter + 1

        if counter > 2 then
            error('Too many networks connected.')
        end

        --- @type me_controller
        local controller = component.proxy(address)

        local subNetworkPaper = controller.getItemsInNetwork({
            name = "minecraft:paper",
            label = "SubNetwork",
        })

        if #subNetworkPaper == 0 then
            mainNetwork = controller
        else
            subNetwork = controller
        end
    end
    
    return mainNetwork, subNetwork
end

function registerOutputs()
    local outputs = {}
    
    for address, _ in component.list("me_interface") do
        --- @type me_interface
        local interface = component.proxy(address)

        for i = 1, 36 do
            local pattern = interface.getInterfacePattern(i)

            if pattern == nil then
                goto continue
            end

            for _, output in pairs(pattern.outputs) do
                if output.name ~= nil then
                    if output.name == "Paper" then
                        goto continue
                    end
                    
                    if outputs[output.name] ~= nil then
                        error("Output: `" .. output.name .. "` has already been registered.")
                    end

                    input = pattern.inputs[1]
                    outputs[output.name] = input.name
                end
            end

            ::continue::
        end
    end
    
    return outputs
end

return initialize