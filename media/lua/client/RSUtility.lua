RealisticShoes = RealisticShoes or {}

RealisticShoes.SIZES = {
    {size=36, chance = 6},
    {size=37, chance = 8},
    {size=38, chance = 12},
    {size=39, chance = 13},
    {size=40, chance = 14},
    {size=41, chance = 13},
    {size=42, chance = 12},
    {size=43, chance = 10},
    {size=44, chance = 7},
    {size=45, chance = 5}
}

RealisticShoes.MEN_SIZES = {
    {size=40, chance=14},
    {size=41, chance=18},
    {size=42, chance=24},
    {size=43, chance=20},
    {size=44, chance=14},
    {size=45, chance=10}
}

RealisticShoes.WOMEN_SIZES = {
    {size=36, chance=12},
    {size=37, chance=16},
    {size=38, chance=24},
    {size=39, chance=26},
    {size=40, chance=14},
    {size=41, chance=8}
}

function RealisticShoes.getRandomMenSize()
    local total = 0
    local rand = ZombRand(100)
    for _, entry in ipairs(RealisticShoes.MEN_SIZES) do
        total = total + entry.chance
        if rand < total then return entry.size end
    end

    return 43
end

function RealisticShoes.getRandomWomenSize()
    local total = 0
    local rand = ZombRand(100)
    for _, entry in ipairs(RealisticShoes.WOMEN_SIZES) do
        total = total + entry.chance
        if rand < total then return entry.size end
    end

    return 38
end

function RealisticShoes.getRandomSize(onChar, isFemale)
    if onChar then
        if isFemale then
            return RealisticShoes.getRandomWomenSize()
        else
            return RealisticShoes.getRandomMenSize()
        end
    else
        local total = 0
        local rand = ZombRand(100)
        for _, entry in ipairs(RealisticShoes.SIZES) do
            total = total + entry.chance
            if rand < total then return entry.size end
        end
    end
    
    return 40.5
end

function RealisticShoes.getPlayerSize(player)
    return RealisticShoes.getPlayerOriginalSize(player) + RealisticShoes.getPlayerExtraSize(player)
end

function RealisticShoes.getPlayerOriginalSize(player)
    if not player:getModData().RealisticShoes then
        player:getModData().RealisticShoes = {
            size = RealisticShoes.getRandomSize(true, player:isFemale())
        }
    end

    return player:getModData().RealisticShoes.size
end

function RealisticShoes.getPlayerExtraSize(player)
    local weight = player:getNutrition():getWeight()
    if weight >= 100 then
        return 1
    elseif weight >= 85 then
        return 0.5
    end

    return 0
end

function RealisticShoes.getOrCreateModData(shoes, size)
    local data = shoes:getModData()
    if not data.RealisticShoes then
        if not size then
            size = RealisticShoes.getRandomSize(false)
        end

        data.RealisticShoes = {size = size, reveal = false, hint = false}
    end

    return data.RealisticShoes
end

function RealisticShoes.hasModData(item)
    local data = item:getModData()
    return data and data.RealisticShoes
end

function RealisticShoes.getSizeText(size)
    return "EU " .. size
end

function RealisticShoes.getHintText(diff)
    local text
    if diff < -1 then
        text = getText("IGUI_Hint_Shoes_Too_Tight")
    elseif diff == -1 then
        text = getText("IGUI_Hint_Shoes_Tight")
    elseif diff < 0 then
        text = getText("IGUI_Hint_Shoes_Slightly_Tight")
    elseif diff == 0 then
        text = getText("IGUI_Hint_Shoes_Fit")
    elseif diff < 1 then
        text = getText("IGUI_Hint_Shoes_Slightly_Loose")
    elseif diff == 1 then
        text = getText("IGUI_Hint_Shoes_Loose")
    else
        text = getText("IGUI_Hint_Shoes_Too_Loose")
    end

    return "(" .. text .. ")"
end

function RealisticShoes.getDiffText(diff, size)
    local text
    if diff < -1 then
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Too_Tight0") or getText("IGUI_Say_Shoes_Too_Tight1")
    elseif diff == -1 then
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Tight0") or getText("IGUI_Say_Shoes_Tight1")
    elseif diff < 0 then
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Slightly_Tight0") or getText("IGUI_Say_Shoes_Slightly_Tight1")
    elseif diff == 0 then
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Fit0") or getText("IGUI_Say_Shoes_Fit1")
    elseif diff < 1 then
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Slightly_Loose0") or getText("IGUI_Say_Shoes_Slightly_Loose1")
    elseif diff == 1 then
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Loose0") or getText("IGUI_Say_Shoes_Loose1")
    else
        text = ZombRand(2) == 0 and getText("IGUI_Say_Shoes_Too_Loose0") or getText("IGUI_Say_Shoes_Too_Loose1")
    end

    if size ~= nil then
        text = RealisticShoes.getSizeText(size) .. '. ' .. text
    end

    return text
end

function RealisticShoes.isShoes(item)
    return item and instanceof(item, "Clothing") and item:getBodyLocation() == "Shoes"
end

function RealisticShoes.getAdditionalWeightStr(player)
    local extraSize = RealisticShoes.getPlayerExtraSize(player)

    return 'EU ' .. RealisticShoes.getPlayerOriginalSize(player) .. (extraSize > 0 and ('+' .. extraSize) or '')
end

function RealisticShoes.addCheckSizeOption(items, player, context)
    local listShoes = {}
    for _, v in ipairs(items) do
        if type(v) == 'table' then
            if v.items and #v.items > 1 then
                for j = 2, #v.items do
                    local e = v.items[j]
                    if RealisticShoes.isShoes(e) then
                        if not RealisticShoes.hasModData(e) or not RealisticShoes.getOrCreateModData(e).reveal then
                            table.insert(listShoes, e)
                        end
                    end
                end
            end
        else
            if RealisticShoes.isShoes(v) then
                if not RealisticShoes.hasModData(v) or not RealisticShoes.getOrCreateModData(v).reveal then
                    table.insert(listShoes, v)
                end
            end
        end
    end

    if #listShoes > 0 then
        context:addOption(getText("IGUI_JobType_CheckShoesSize"), player, RealisticShoes.checkShoesSize, listShoes)
    end
end

function RealisticShoes.checkShoesSize(player, items)
    local inv = player:getInventory()
    for _, item in ipairs(items) do
        local container = item:getContainer()
        if container and container ~= inv then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, container, inv))
        end
        ISTimedActionQueue.add(ISCheckShoesSize:new(player, item))
    end
end

function RealisticShoes.getColorForPercent(percent)
    local color = ColorInfo.new(0, 0, 0, 1)
    getCore():getBadHighlitedColor():interp(getCore():getGoodHighlitedColor(), percent, color)
    return " <RGB:" .. color:getR() .. "," .. color:getG() .. "," .. color:getB() .. "> "
end

function RealisticShoes.getPotentialRepairForRecondition(item, player)
    return 0
end

function RealisticShoes.getSuccessChanceForRecondition(item, player)
    return 0
end

function RealisticShoes.getRequiredMaterialsForRecondition(player, materialType, quantity)
    local allMaterials = player:getInventory():getItemsFromType(materialType, true)
    if allMaterials:size() >= quantity then
        local materials = {}
        for i = 0, quantity - 1 do
            table.insert(materials, allMaterials:get(i))
        end
        return materials, allMaterials:size()
    else
        return nil, allMaterials:size()
    end
end

function RealisticShoes.addReconditionOption(item, player, context)
    if item:getCondition() == item:getConditionMax() then return end

    local repairedTimes = RealisticShoes.getRepairedTimes(item)
    local potentialRepair = RealisticShoes.getPotentialRepairForRecondition(item, player)
    local successChance = RealisticShoes.getSuccessChanceForRecondition(item, player)

    local option = context:addOption(getText("IGUI_JobType_ReconditionShoes"))
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    local repairOptions = {
        ["Base.Glue"] = 2,
        ["Base.DuctTape"] = 2,
        ["Base.Scotchtape"] = 2
    }

    for materialType, quantity in pairs(repairOptions) do
        local materials, count = RealisticShoes.getRequiredMaterialsForRecondition(player, materialType, quantity)
        local subOption = subMenu:addOption(getText("IGUI_JobType_ReconditionShoes_UseMaterials", quantity, getItemNameFromFullType(materialType)), player, RealisticShoes.reconditionShoes, materials)
        subOption.notAvailable = not materials
        subOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
        subOption.toolTip.description = RealisticClothes.getColorForPercent(potentialRepair) .. getText("Tooltip_potentialRepair") .. " " .. math.ceil(potentialRepair * 100) .. "%"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. RealisticClothes.getColorForPercent(successChance) .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(successChance * 100) .. "%"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. (count >= quantity and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType(materialType) .. " " .. count .. "/" .. quantity
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,0.8> " .. getText("Tooltip_weapon_Repaired") .. ": " .. (repairedTimes == 0 and getText("Tooltip_never") or (repairedTimes .. "x"))
    end
end

function RealisticShoes.reconditionShoes(player, item, materials)
    ISInventoryPaneContextMenu.transferIfNeeded(player, materials)

    if player:isEquippedClothing(item) then
        ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
    else
        ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    end

    ISTimedActionQueue.add(ISReconditionShoes:new(player, item, materials))
end