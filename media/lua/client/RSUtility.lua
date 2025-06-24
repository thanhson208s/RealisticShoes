RealisticShoes = RealisticShoes or {}

RealisticShoes.SHOE_NAMES = {
    "Shoes", "Boots", "Sneakers"
}

function RealisticShoes.canResizeShoes(item)
    local name = item:getDisplayName():lower()
    for _, shoeType in ipairs(RealisticShoes.SHOE_NAMES) do
        if name:find(shoeType:lower(), 1, true) then
            return true
        end
    end
    return false
end

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

RealisticShoes.DEFAULT_MEN_SIZE = 42
RealisticShoes.DEFAULT_WOMEN_SIZE = 39

function RealisticShoes.getRandomMenSize()
    local total = 0
    local rand = ZombRand(100)
    for _, entry in ipairs(RealisticShoes.MEN_SIZES) do
        total = total + entry.chance
        if rand < total then return entry.size end
    end

    return RealisticShoes.DEFAULT_MEN_SIZE
end

function RealisticShoes.getStartingMenSize()
    local pool = {}
    local totalChance = 0
    for _, menSize in ipairs(RealisticShoes.MEN_SIZES) do
        for _, allowedSize in ipairs(RealisticShoes.StartingMenSizes) do
            if menSize.size == allowedSize then
                table.insert(pool, menSize)
                totalChance = totalChance + menSize.chance
                break
            end
        end
    end

    if #pool == 0 then return RealisticShoes.DEFAULT_MEN_SIZE end

    local rand = ZombRand(totalChance)
    local total = 0
    for _, menSize in ipairs(pool) do
        total = total + menSize.chance
        if rand < total then return menSize.size end
    end

    return RealisticShoes.DEFAULT_MEN_SIZE
end

function RealisticShoes.getRandomWomenSize()
    local total = 0
    local rand = ZombRand(100)
    for _, entry in ipairs(RealisticShoes.WOMEN_SIZES) do
        total = total + entry.chance
        if rand < total then return entry.size end
    end

    return DEFAULT_WOMEN_SIZE
end

function RealisticShoes.getStartingWomenSize()
    local pool = {}
    local totalChance = 0
    for _, womenSize in ipairs(RealisticShoes.WOMEN_SIZES) do
        for _, allowedSize in ipairs(RealisticShoes.StartingWomenSizes) do
            if womenSize.size == allowedSize then
                table.insert(pool, womenSize)
                totalChance = totalChance + womenSize.chance
                break
            end
        end
    end

    if #pool == 0 then return RealisticShoes.DEFAULT_WOMEN_SIZE end

    local rand = ZombRand(totalChance)
    local total = 0
    for _, womenSize in ipairs(pool) do
        total = total + womenSize.chance
        if rand < total then return womenSize.size end
    end

    return RealisticShoes.DEFAULT_WOMEN_SIZE
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

    return (RealisticShoes.DEFAULT_MEN_SIZE + RealisticShoes.DEFAULT_WOMEN_SIZE) / 2
end

function RealisticShoes.getPlayerSize(player)
    return RealisticShoes.getPlayerOriginalSize(player) + RealisticShoes.getPlayerExtraSize(player)
end

function RealisticShoes.getPlayerOriginalSize(player)
    local alreadyHasSize = false
    if player:getModData().RealisticShoes then
        local size = player:getModData().RealisticShoes.size
        local allowedSizes = player:isFemale() and RealisticShoes.StartingWomenSizes or RealisticShoes.StartingMenSizes
        for _, allowedSize in ipairs(allowedSizes) do
            if allowedSize == size then
                alreadyHasSize = true
                break
            end
        end
    end

    if not alreadyHasSize then
        player:getModData().RealisticShoes = {
            size = player:isFemale() and RealisticShoes.getStartingWomenSize() or RealisticShoes.getStartingMenSize()
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

        data.RealisticShoes = {size = size, reveal = false, hint = false, resized = 0}
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

function RealisticShoes.getShoesDifficutly(item)
    local defense = (item:getScratchDefense() or 0.0) + 2 * (item:getBiteDefense() or 0.0)
    return math.floor(math.sqrt(defense / 20.0))
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

function RealisticShoes.getPotentialRepairUsingSpare(item, player, spareItem)
    return 0
end

function RealisticShoes.getSuccessChanceUsingSpare(item, player,spareItem)
    return 0
end

function RealisticShoes.getRequiredLevelToRecondition(item, usingSpare)
    if not RealisticShoes.NeedTailoringLevel then return 0 end

    return RealisticShoes.getShoesDifficutly(item) + (usingSpare and 1 or 0)
end

function RealisticShoes.getRequiredMaterialsForRecondition(player, materialType, quantity)
    local allMaterials = player:getInventory():getItemsFromType(materialType, true)
    local materials = {}
    local total = 0
    for i = 0, allMaterials:size() - 1 do
        if total < quantity then
            table.insert(materials, allMaterials:get(i))
        end
        total = total + RealisticShoes.getUseCount(allMaterials:get(i))
    end

    return total >= quantity and materials or nil, total
end

function RealisticShoes.predicateScissors(item)
    if item:isBroken() then return false end
    return item:hasTag("Scissors") or item:getType() == "Scissors"
end

function RealisticShoes.addReconditionOption(item, player, context)
    if item:getCondition() == item:getConditionMax() then return end

    local requiredLevel = RealisticShoes.getRequiredLevelToRecondition(item, false)
    local repairedTimes = RealisticShoes.getRepairedTimes(item)
    local potentialRepair = math.max(0, math.min(1, RealisticShoes.getPotentialRepairForRecondition(item, player)))
    local successChance = math.max(0, math.min(1, RealisticShoes.getSuccessChanceForRecondition(item, player)))
    local tailoring = player:getPerkLevel(Perks.Tailoring)

    local option = context:addOption(getText("IGUI_JobType_ReconditionShoes"))
    local subMenu = context:getNew(context)
    context:addSubMenu(option, subMenu)

    local repairOptions = RealisticShoes.RepairOptions
    local repairMaterials = {}
    for materialType, quantity in pairs(repairOptions) do
        local materials, count = RealisticShoes.getRequiredMaterialsForRecondition(player, materialType, quantity)
        local materialName = getItemNameFromFullType(materialType)
        local subOption = subMenu:addOption(getText("IGUI_JobType_ReconditionShoes_UseMaterials", quantity, materialName), player, RealisticShoes.reconditionShoes, materials)
        subOption.notAvailable = not (materials and tailoring >= requiredLevel)
        subOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
        subOption.toolTip.description = RealisticShoes.getColorForPercent(potentialRepair) .. getText("Tooltip_potentialRepair") .. " " .. math.ceil(potentialRepair * 100) .. "%"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. RealisticShoes.getColorForPercent(successChance) .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(successChance * 100) .. "%"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. (count >= quantity and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. materialName .. " " .. count .. "/" .. quantity
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. (tailoring >= requiredLevel and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. PerkFactory.getPerk(Perks.Tailoring):getName() .. " " .. tailoring .. "/" .. requiredLevel
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,0.8> " .. getText("Tooltip_weapon_Repaired") .. ": " .. (repairedTimes == 0 and getText("Tooltip_never") or (repairedTimes .. "x"))

        repairMaterials[materialType] = {name = materialName, materials = materials, count = count}
    end

    local scissors = player:getInventory():getFirstEvalRecurse(RealisticShoes.predicateScissors)
    local spareItems = player:getInventory():getItemsFromType(item:getFullType(), true)
    local hasSpareItems = false
    for i = 0, spareItems:size() - 1 do
        local spareItem = spareItems:get(i)
        if spareItem ~= item then
            hasSpareItems = true

            requiredLevel = RealisticShoes.getRequiredLevelToRecondition(item, true)
            potentialRepair = RealisticShoes.getPotentialRepairUsingSpare(item, player, spareItem)
            successChance = RealisticShoes.getSuccessChanceUsingSpare(item, player, spareItem)

            local name = getItemNameFromFullType(spare:getFullType())
            if RealisticShoes.hasModData(spareItem) then
                local data = RealisticShoes.getOrCreateModData(spareItem)
                if data and data.reveal then name = name .. ' (' .. RealisticShoes.getSizeText(data.size) .. ')' end
            end

            local subOption = subMenu:addOption(getText("IGUI_JobType_ReconditionShoes_UseSpare", name))
            local spareMenu = subMenu:getNew(subMenu)
            subMenu:addSubMenu(subOption, spareMenu)

            for materialType, materialData in pairs(repairMaterials) do
                local quantity = repairOptions[materialType]
                local materials = materialData.materials
                local spareOption = spareMenu:addOption(getText("IGUI_JobType_ReconditionShoes_UseMaterials", quantity, materialData.name), player, Realistic.reconditionShoesUsingSpare, item, scissors, spareItem, materials)
                spareOption.notAvailable = not (scissors and materials and tailoring >= requiredLevel)
                spareOption.toolTip.description = RealisticShoes.getColorForPercent(potentialRepair) .. getText("Tooltip_potentialRepair") .. " " .. math.ceil(potentialRepair * 100) .. "%"
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE>" .. RealisticShoes.getColorForPercent(successChance) .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(successChance * 100) .. "%"
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE>" .. (scissors ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Scissors")
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE>" .. ISInventoryPaneContextMenu.ghs .. name
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE>" .. (materialData.count >= quantity and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. materialName .. " " .. material.count .. "/" .. quantity
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE>" .. (tailoring >= requiredLevel and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. PerkFactory.getPerk(Perks.Tailoring):getName() .. " " .. tailoring .. "/" .. requiredLevel
                spareOption.toolTip.description = spareOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,0.8> " .. getText("Tooltip_weapon_Repaired") .. ": " .. (repairedTimes == 0 and getText("Tooltip_never") or (repairedTimes .. "x"))
            end
        end
    end

    if not hasSpareItems then
        local name = getItemNameFromFullType(item:getFullType())
        requiredLevel = RealisticShoes.getRequiredLevelToRecondition(item, true)

        local subOption = subMenu:addOption(getText("IGUI_JobType_ReconditionShoes_UseSpare", name))
        subOption.notAvailable = true
        subOption.toolTip = ISInventoryPaneContextMenu.addToolTip()
        subOption.toolTip.description = RealisticShoes.getColorForPercent(0.5) .. getText("Tooltip_potentialRepair") .. " ???"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. RealisticShoes.getColorForPercent(0.5) .. getText("Tooltip_chanceSuccess") .. " ???"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. (scissors ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Scissors")
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. ISInventoryPaneContextMenu.bhs .. name
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. getText("IGUI_CraftUI_OneOf")
        for materialType, materialData in pairs(repairMaterials) do
            local quantity = repairOptions[materialType]
            subOption.toolTip.description = subOption.toolTip.description .. " <LINE> <INDENT:20> " .. (materialData.count >= quantity and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. materialData.name .. " " .. materialData.count .. "/" .. quantity .. " <INDENT:0> "
        end
        subOption.toolTip.description = subOption.toolTip.description .. " <LINE>" .. (tailoring >= requiredLevel and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. PerkFactory.getPerk(Perks.Tailoring):getName() .. " " .. tailoring .. "/" .. requiredLevel
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

function RealisticShoes.reconditionShoesUsingSpare(player, item, scissors, spareItem, materials)
    ISInventoryPaneContextMenu.transferIfNeeded(player, scissors)
    ISInventoryPaneContextMenu.transferIfNeeded(player, spareItem)
    ISInventoryPaneContextMenu.transferIfNeeded(player, materials)

    if player:isEquippedClothing(item) then
        ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
    else
        ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    end

    ISTimedActionQueue.add(ISReconditionShoesUsingSpare:new(player, item, scissors, spareItem, materials))
end

RealisticShoes.OriginalStats = {}

function RealisticShoes.getOriginalStats(item)
    local fullType = item:getFullType()
    if not RealisticShoes.OriginalStats[fullType] then
        local sampleItem = RealisticShoes.createItem(fullType)
        RealisticShoes.OriginalStats[fullType] = {
            insulation = sampleItem:getInsulation() or 0,
            stompPower = sampleItem:getStompPower() or 0,
            runSpeedMod = sampleItem:getRunSpeedModifier() or 0
        }
    end

    return RealisticShoes.OriginalStats[fullType]
end

function RealisticShoes.getInsulationReduction(diff)
    return 0.5 + 0.5 / (1 + RealisticShoes.InsulationReduceMultiplier * diff)
end

function RealisticShoes.getStompPowerReduction(diff)
    return 0.5 + 0.5 / (1 + RealisticShoes.StompPowerReduceMultiplier * diff)
end

function RealisticShoes.updateShoesByDiff(shoes, player)
    if not (shoes and instanceof(shoes, "Clothing")) then return end

    local stats = RealisticShoes.getOriginalStats(shoes)
    local insulation = stats.insulation
    local stompPower = stats.stompPower
    local runSpeedMod = stats.runSpeedMod

    if player:isEquippedClothing(shoes) then
        local playerSize = RealisticShoes.getPlayerSize(player)
        local data = RealisticShoes.getOrCreateModData(shoes)
        local diff = data.size - playerSize

        if diff > 0 then
            insulation = insulation * RealisticShoes.getInsulationReduction(diff)
            stompPower = stompPower * RealisticShoes.getStompPowerReduction(diff)
            runSpeedMod = runSpeedMod - diff * 0.5  -- cosmetic only
        end
    end

    shoes:setInsulation(math.min(insulation, 1))
    shoes:setStompPower(math.max(stompPower, 0))
    shoes:setRunSpeedModifier(math.max(runSpeedMod, 0))
end

function RealisticShoes.addUpsizeOption(shoes, player, context)
    
end

function RealisticShoes.addDownsizeOption(shoes, player, context)
end