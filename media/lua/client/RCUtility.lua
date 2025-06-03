-- TODO: Use an identical item to resize or recondition another

RealisticClothes = RealisticClothes or {}

function RealisticClothes.debugLog(str)
    if RealisticClothes.Debug then
        print(str)
    end
end

RealisticClothes.SIZES = {
    XS = {name = 'XS', chance = 5, includes = function(x) return x <= 50 end},
    S = {name = 'S', chance = 10, includes = function(x) return x > 50 and x <= 65 end},
    M = {name = 'M', chance = 25, includes = function(x) return x > 65 and x <= 75 end},
    L = {name = 'L', chance = 35, includes = function(x) return x > 75 and x < 85 end},
    XL = {name = 'XL', chance = 15, includes = function(x) return x >= 85 and x < 100 end},
    XXL = {name = 'XXL', chance = 10, includes = function(x) return x >= 100 end}
}

RealisticClothes.SIZE_LIST = {
    RealisticClothes.SIZES.XS,
    RealisticClothes.SIZES.S,
    RealisticClothes.SIZES.M,
    RealisticClothes.SIZES.L,
    RealisticClothes.SIZES.XL,
    RealisticClothes.SIZES.XXL
}

RealisticClothes.OriginalInsulation = {}
RealisticClothes.OriginalCombatSpeedModifier = {}
RealisticClothes.DiffByBodyPart = {}

function RealisticClothes.getSizeIndex(name)
    for i, size in ipairs(RealisticClothes.SIZE_LIST) do
        if size.name == name then
            return i
        end
    end
end

function RealisticClothes.getNextSize(name)
    local index = RealisticClothes.getSizeIndex(name)
    if index and index < #RealisticClothes.SIZE_LIST then
        return RealisticClothes.SIZE_LIST[index + 1]
    end
end

function RealisticClothes.getPrevSize(name)
    local index = RealisticClothes.getSizeIndex(name)
    if index and index > 1 then
        return RealisticClothes.SIZE_LIST[index - 1]
    end
end

-- Get player's size based on weight
function RealisticClothes.getPlayerSize(player)
    local weight = player:getNutrition():getWeight()
    for _, size in pairs(RealisticClothes.SIZE_LIST) do
        if size.includes(weight) then
            return size
        end
    end

    return RealisticClothes.SIZES.L
end

-- Find clothes's size object based on name
function RealisticClothes.getClothesSizeFromName(name)
    for _, size in pairs(RealisticClothes.SIZE_LIST) do
        if size.name == name then
            return size
        end
    end

    return RealisticClothes.SIZES.L
end

-- Get the size difference of clothes and player
function RealisticClothes.getSizeDiff(clothesSize, playerSize)
    local function indexOf(sizeObj)
        for i, s in ipairs(RealisticClothes.SIZE_LIST) do
            if s == sizeObj then
                return i
            end
        end
        return nil
    end

    local clothesIndex = indexOf(clothesSize)
    local playerIndex = indexOf(playerSize)

    if not clothesIndex or not playerIndex then
        return nil
    end

    return clothesIndex - playerIndex
end

-- Hint to display in clothes's tooltip
function RealisticClothes.getHintText(diff)
    if diff < -2 then
        return getText("IGUI_Hint_Very_Tight")
    elseif diff < 0 then
        return getText("IGUI_Hint_Tight")
    elseif diff == 0 then
        return getText("IGUI_Hint_Fit")
    elseif diff > 2 then
        return getText("IGUI_Hint_Very_Loose")
    else
        return getText("IGUI_Hint_Loose")
    end
end

-- Text for player to say after trying to wear clothes
function RealisticClothes.getHintFromSizeDiff(diff)
    if diff < -2 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Hint_Very_Tight0") or getText("IGUI_Say_Hint_Very_Tight1")
    elseif diff < 0 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Hint_Tight0") or getText("IGUI_Say_Hint_Tight1")
    elseif diff == 0 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Hint_Fit0") or getText("IGUI_Say_Hint_Fit1")
    elseif diff > 2 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Hint_Very_Loose0") or getText("IGUI_Say_Hint_Very_Loose1")
    else
        return ZombRand(2) == 0 and getText("IGUI_Say_Hint_Loose0") or getText("IGUI_Say_Hint_Loose1")
    end
end

-- Text for player to say after checking clothes's size
function RealisticClothes.getTextFromSizeDiff(diff, size)
    if diff < -2 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Label_Very_Tight0", size.name) or getText("IGUI_Say_Label_Very_Tight1", size.name)
    elseif diff < 0 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Label_Tight0", size.name) or getText("IGUI_Say_Label_Tight1", size.name)
    elseif diff == 0 then  
        return ZombRand(2) == 0 and getText("IGUI_Say_Label_Fit0", size.name) or getText("IGUI_Say_Label_Fit1", size.name)
    elseif diff > 2 then
        return ZombRand(2) == 0 and getText("IGUI_Say_Label_Very_Loose0", size.name) or getText("IGUI_Say_Label_Very_Loose1", size.name)
    else
        return ZombRand(2) == 0 and getText("IGUI_Say_Label_Loose0", size.name) or getText("IGUI_Say_Label_Loose1", size.name)
    end
end

-- New random size based on distribution table
function RealisticClothes.getRandomClothesSize()
    local totalChance = 0
    for _, size in pairs(RealisticClothes.SIZE_LIST) do
        totalChance = totalChance + size.chance
    end

    local rand = ZombRand(totalChance)
    local cumulative = 0

    for _, size in pairs(RealisticClothes.SIZE_LIST) do
        cumulative = cumulative + size.chance
        if rand < cumulative then
            return size
        end
    end

    return RealisticClothes.SIZES.L
end

function RealisticClothes.hasModData(item)
    local data = item:getModData()
    return data and data.RealisticClothes
end

function RealisticClothes.getOrCreateModData(item, initSize)
    local data = item:getModData()
    if not data.RealisticClothes then
        local sizeName
        if initSize and type(initSize) == "string" then
            local idx
            for i, s in ipairs(RealisticClothes.SIZE_LIST) do
                if s.name == initSize then
                    idx = i
                    break
                end
            end

            if idx then
                local candidates = {}
                local totalW = 0
                local localW = {[-1]=25, [0]=60, [1]=15}

                for offset, lw in pairs(localW) do
                    local i = idx + offset
                    if i >= 1 and i <= #RealisticClothes.SIZE_LIST then
                        local w = RealisticClothes.SIZE_LIST[i].chance
                        table.insert(candidates, {name = RealisticClothes.SIZE_LIST[i].name, weight = w * lw})
                        totalW = totalW + w * lw
                    end
                end

                local rand = ZombRand(totalW)
                local cumulative = 0
                for _, candidate in ipairs(candidates) do
                    cumulative = cumulative + candidate.weight
                    if rand < cumulative then
                        sizeName = candidate.name
                        break
                    end
                end
            end
        end
        if not sizeName then
            sizeName = RealisticClothes.getRandomClothesSize().name
        end

        -- new clothes might have small chance to be resized already
        local resized = 0
        if ZombRandFloat(0, 1) < 0.1 then
            local idx = RealisticClothes.getSizeIndex(sizeName)
            if ZombRandFloat(0, 1) < 0.5 then
                if idx < #RealisticClothes.SIZE_LIST then
                    resized = -1
                end
            else
                if idx > 1 then
                    resized = 1
                end
            end
        end

        data.RealisticClothes = {size = sizeName, reveal = false, hint = false, resized = resized}
    end
    return data.RealisticClothes
end

function RealisticClothes.getDiffForBodyPart(player, bodyPartType)
    local playerData = RealisticClothes.DiffByBodyPart

    return playerData and playerData[bodyPartType] or 0
end

function RealisticClothes.setDiffForBodyPart(player, bodyPartType, diff)
    local playerData = RealisticClothes.DiffByBodyPart

    playerData[bodyPartType] = math.min(playerData[bodyPartType] or 0, diff)
end

-- canDrop: can loose clothes (bottom) drop (if no belt and no free hands)
-- insulationMod: can loose clothes have decreased insulation
-- combatMod: can loose clothes (top) reduce combat speed
-- incTrip: can loose clothes (bottom) increase trip chance
-- incStiffness: can tight clothes cause stiffness overtime while running, sprinting, swinging weapon, doing fitness
RealisticClothes.CLOTHES_SLOTS = {
    -- top only
    TankTop         = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=1},
    Tshirt          = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=1},
    ShortSleeveShirt= {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=1},
    Shirt           = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=1},
    Sweater         = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=2},
    SweaterHat      = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=2},
    Jacket          = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=2},
    Jacket_Down     = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=2},
    Jacket_Bulky    = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=3},
    JacketHat       = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=2},
    JacketHat_Bulky = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=3},
    JacketSuit      = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=2},
    Torso1          = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=false, incStiffness=true, difficulty=1},

    -- bottom only
    Skirt           = {canRip = true, canDrop = true, insulationMod = true, combatMod=false, incTrip=true, incStiffness=true, difficulty=1},
    Pants           = {canRip = true, canDrop = true, insulationMod = true, combatMod=false, incTrip=true, incStiffness=true, difficulty=1},
    Legs1           = {canRip = true, canDrop = true, insulationMod = true, combatMod=false, incTrip=true, incStiffness=true, difficulty=1},

    -- top and bottom
    Dress           = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=true, incStiffness=true, difficulty=3},
    Boilersuit      = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=true, incStiffness=true, difficulty=3},
    Torso1Legs1     = {canRip = true, canDrop = false, insulationMod = true, combatMod=true, incTrip=true, incStiffness=true, difficulty=2},
}

RealisticClothes.FabricTypeDifficulty = {
    Cotton = 0, Denim = 1, Leather = 2
}

function RealisticClothes.getClothesFabricType(item)
    local fabricType = item:getScriptItem():getFabricType()
    return RealisticClothes.FabricTypeDifficulty[fabricType] ~= nil and fabricType or nil
end

function RealisticClothes.getStripType(fabricType)
    if fabricType == 'Cotton' then
        return "Base.RippedSheets"
    elseif fabricType == 'Denim' then
        return "Base.DenimStrips"
    elseif fabricType == 'Leather' then
        return "Base.LeatherStrips"
    end

    return nil
end

function RealisticClothes.getRequiredLevelToCheck(item)
    if not RealisticClothes.NeedTailoringLevel then return 0 end

    return math.max(RealisticClothes.CLOTHES_SLOTS[item:getBodyLocation()].difficulty - 1, 0)
end

function RealisticClothes.getCheckDuration(item)
    return RealisticClothes.CLOTHES_SLOTS[item:getBodyLocation()].difficulty * 100
end

function RealisticClothes.getRequiredLevelToChange(item, isUpsizing)
    if not RealisticClothes.NeedTailoringLevel then return 0 end

    local difficulty = RealisticClothes.CLOTHES_SLOTS[item:getBodyLocation()].difficulty
    difficulty = difficulty + (RealisticClothes.FabricTypeDifficulty[item:getScriptItem():getFabricType()] or 0)
    if isUpsizing then difficulty = difficulty + 1 end

    return difficulty
end

function RealisticClothes.getChangeDuration(item, isUpsizing)
    local duration = RealisticClothes.CLOTHES_SLOTS[item:getBodyLocation()].difficulty * 200
    duration = duration + (RealisticClothes.FabricTypeDifficulty[item:getScriptItem():getFabricType()] or 0) * 100
    if isUpsizing then duration = duration + 400 end

    return duration
end

function RealisticClothes.getSuccessChanceForChange(tailoring, requiredLevel)
    return tailoring >= requiredLevel and (0.5 + (tailoring - requiredLevel) * 0.25) or 0
end

function RealisticClothes.getTailoringXpForChange(item, isUpsizing, isSuccess)
    local xp = RealisticClothes.CLOTHES_SLOTS[item:getBodyLocation()].difficulty * 5
    xp = xp + (RealisticClothes.FabricTypeDifficulty[item:getScriptItem():getFabricType()] or 0) * 2.5
    if isUpsizing then xp = xp + 10 end

    return xp * RealisticClothes.TailoringXpMultiplier * (isSuccess and 1 or 0.2)
end

function RealisticClothes.getRequiredStripCount(item)
    local location = item:getBodyLocation()
    if RealisticClothes.CLOTHES_SLOTS[location] then
        return RealisticClothes.CLOTHES_SLOTS[location].difficulty * 2
    end
    return 0
end

function RealisticClothes.getRequiredPaperclip(item)
    local location = item:getBodyLocation()
    if RealisticClothes.CLOTHES_SLOTS[location] then
        return RealisticClothes.CLOTHES_SLOTS[location].difficulty * 2
    end
    return 0
end

function RealisticClothes.getRequiredThreadCount(item)
    local location = item:getBodyLocation()
    if RealisticClothes.CLOTHES_SLOTS[location] then
        return RealisticClothes.CLOTHES_SLOTS[location].difficulty * 2
    end
    return 0
end

function RealisticClothes.canClothesHaveSize(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] ~= nil
end

function RealisticClothes.canResizeClothes(item)
    return RealisticClothes.canClothesHaveSize(item) and RealisticClothes.getClothesFabricType(item)
end

function RealisticClothes.canClothesRip(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] and RealisticClothes.CLOTHES_SLOTS[location].canRip
end

function RealisticClothes.canClothesDrop(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] and RealisticClothes.CLOTHES_SLOTS[location].canDrop
end

function RealisticClothes.doesClothesHaveInsulationMod(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] and RealisticClothes.CLOTHES_SLOTS[location].insulationMod
end

function RealisticClothes.doesClothesHaveCombatMod(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] and RealisticClothes.CLOTHES_SLOTS[location].combatMod
end

function RealisticClothes.doesClothesIncreaseTrip(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] and RealisticClothes.CLOTHES_SLOTS[location].incTrip
end

function RealisticClothes.doesClothesIncreaseStiffness(item)
    local location = item:getBodyLocation()
    return RealisticClothes.CLOTHES_SLOTS[location] and RealisticClothes.CLOTHES_SLOTS[location].incStiffness
end

function RealisticClothes.getClothesRipChance(diff)
    return math.abs(diff) * RealisticClothes.RipChanceMultiplier
end

function RealisticClothes.getClothesDropChance(diff)
    return (diff ^ 2) * RealisticClothes.DropChanceMultiplier / 60
end

function RealisticClothes.getInsulationReduction(diff)
    return (0.5 + 0.5 / (1 + RealisticClothes.InsulationReduceMultiplier * diff))
end

function RealisticClothes.getCombatSpeedReduction(diff)
    return 0.05 * 2 ^ (diff - 1) * RealisticClothes.CombatSpeedReduceMultiplier
end

function RealisticClothes.getExtraTripChance(diff)
    return 5 * diff * RealisticClothes.IncreaseTripChanceMultiplier
end

function RealisticClothes.getExtraStiffness(diff)
    return math.abs(diff) * RealisticClothes.IncreaseStiffnessMultiplier
end

function RealisticClothes.getOriginalInsulation(item)
    local fullType = item:getFullType()
    if not RealisticClothes.OriginalInsulation[fullType] then
        RealisticClothes.OriginalInsulation[fullType] = ScriptManager.instance:getItem(fullType):getInsulation()
    end

    return RealisticClothes.OriginalInsulation[fullType]
end

function RealisticClothes.getOriginalCombatSpeedModifier(item)
    local fullType = item:getFullType()
    if not RealisticClothes.OriginalCombatSpeedModifier[fullType] then
        RealisticClothes.OriginalCombatSpeedModifier[fullType] = InventoryItemFactory.CreateItem(fullType):getCombatSpeedModifier()
    end

    return RealisticClothes.OriginalCombatSpeedModifier[fullType]
end

function RealisticClothes.updateClothesStats(item, player, diff)
    local insulation = RealisticClothes.getOriginalInsulation(item)
    local combatMod = RealisticClothes.getOriginalCombatSpeedModifier(item)

    if player:isEquippedClothing(item) then
        if diff > 0 then
            if RealisticClothes.doesClothesHaveInsulationMod(item) then
                insulation = insulation * RealisticClothes.getInsulationReduction(diff)
            end
            if RealisticClothes.doesClothesHaveCombatMod(item) then
                combatMod = combatMod - RealisticClothes.getCombatSpeedReduction(diff)
            end
        end

        if diff < 0 and RealisticClothes.doesClothesIncreaseStiffness(item) then 
            local bodyPartTypes = BloodClothingType.getCoveredParts(item:getBloodClothingType())
            for i = 0, bodyPartTypes:size() - 1 do
                local bodyPartType = BodyPartType.FromIndex(BloodBodyPartType.ToIndex(bodyPartTypes:get(i)))
                RealisticClothes.setDiffForBodyPart(player, bodyPartType, diff)
            end
        end
    end

    item:setInsulation(math.min(insulation, 1))
    item:setCombatSpeedModifier(math.max(combatMod, 0.5))
end

function RealisticClothes.updateAllClothes(player)
    RealisticClothes.DiffByBodyPart = {}

    local list = player:getWornItems()
    local playerSize = RealisticClothes.getPlayerSize(player)

    local canDrop = false
    if not player:isAsleep() and not player:getVehicle() then
        local hasBelt = false
        for i = 0, list:size() - 1 do
            local item = list:getItemByIndex(i)
            if item and item:getBodyLocation() == "Belt" then
                hasBelt = true
                break
            end
        end
        canDrop = not hasBelt and player:getPrimaryHandItem() and player:getSecondaryHandItem()
    end

    for i = 0, list:size() - 1 do
        local item = list:getItemByIndex(i)
        if item and RealisticClothes.canClothesHaveSize(item) then
            local data = RealisticClothes.getOrCreateModData(item)
            local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
            local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)

            if canDrop and RealisticClothes.canClothesDrop(item) and player:isEquippedClothing(item) and diff > 0 then
                local dropChance = RealisticClothes.getClothesDropChance(diff)
                if ZombRandFloat(0, 1) < dropChance then
                    RealisticClothes.dropClothes(item, player)
                end
            end

            -- player's increased size and clothes can no longer fit
            if diff < -2 and player:isEquippedClothing(item) then
                player:getInventory():setDrawDirty(true)
                player:removeWornItem(item)
                triggerEvent("OnClothingUpdated", player)

                player:getEmitter():playSound("PutItemInBag")
                player:Say(ZombRand(2) == 0 and getText("IGUI_Say_Nofit_Clothes0") or getText("IGUI_Say_Nofit_Clothes1"))
            end

            RealisticClothes.updateClothesStats(item, player, diff)
        end
    end
end

function RealisticClothes.updateOneClothes(item, player)
    local data = RealisticClothes.getOrCreateModData(item)
    local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
    local playerSize = RealisticClothes.getPlayerSize(player)
    local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)

    RealisticClothes.updateClothesStats(item, player, diff)
end

function RealisticClothes.ripClothes(item, player)
    if not item:getCanHaveHoles() then return false end

    local candidateParts = {}
    local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
    local visual = item:getVisual()
    for i = 0, coveredParts:size() - 1 do
        local part = coveredParts:get(i)
        if visual:getHole(part) == 0 then
            table.insert(candidateParts, part)
        end
    end
    if #candidateParts == 0 then return false end

    local part = candidateParts[ZombRand(#candidateParts) + 1]
    visual:setHole(part)
    item:removePatch(part)
    item:setCondition(math.max(item:getCondition() - item:getCondLossPerHole()))

    player:getEmitter():playSound("TightClothesRip")
    return true
end

function RealisticClothes.dropClothes(item, player)
    if item:isFavorite() then
        item:setFavorite(false)
    end

    player:removeWornItem(item)
    triggerEvent("OnClothingUpdated", player)

    local square = player:getSquare()
    local x, y, z = ISInventoryTransferAction.GetDropItemOffset(player, square, item)
    player:getInventory():Remove(item)
    square:AddWorldInventoryItem(item, x, y, z)

    player:getEmitter():playSound("PutItemInBag")
    local location = item:getBodyLocation()
    if location == "Skirt" then
        player:Say(ZombRand(2) == 0 and getText("IGUI_Say_Dropped_Skirt0") or getText("IGUI_Say_Dropped_Skirt1"))
    end
    if location == "Pants" then
        player:Say(ZombRand(2) == 0 and getText("IGUI_Say_Dropped_Pants0") or getText("IGUI_Say_Dropped_Pants1"))
    end
end

function RealisticClothes.checkClothesSize(player, items)
    local inv = player:getInventory()
    for i, item in ipairs(items) do
        local container = item:getContainer()
        if container and container ~= inv then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, container, inv))
        end
        ISTimedActionQueue.add(ISCheckClothesSize:new(player, item, RealisticClothes.getCheckDuration(item)))
    end
end

function RealisticClothes.upsizeClothes(player, item, needle, scissors, threads, strips)
    ISInventoryPaneContextMenu.transferIfNeeded(player, threads)
    ISInventoryPaneContextMenu.transferIfNeeded(player, strips)
    if player:isEquippedClothing(item) then
        ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
    else
        ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    end

    ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), scissors, true)
    ISWorldObjectContextMenu.equip(player, player:getSecondaryHandItem(), needle, false)
    ISTimedActionQueue.add(ISUpsizeClothes:new(player, item, needle, scissors, threads, strips))
end

function RealisticClothes.downsizeClothes(player, item, needle, scissors, threads, paperclips)
    ISInventoryPaneContextMenu.transferIfNeeded(player, threads)
    ISInventoryPaneContextMenu.transferIfNeeded(player, paperclips)
    if player:isEquippedClothing(item) then
        ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
    else
        ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    end

    ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), scissors, true)
    ISWorldObjectContextMenu.equip(player, player:getSecondaryHandItem(), needle, false)
    ISTimedActionQueue.add(ISDownsizeClothes:new(player, item, needle, scissors, threads, paperclips))
end

function RealisticClothes.getRemainingThread(threads)
    local total = 0
    for i = 0, threads:size() - 1 do
        total = total + threads:get(i):getRemainingUses()
    end
    return total
end

function RealisticClothes.getColorForPercent(percent)
    local color = ColorInfo.new(0, 0, 0, 1)
    getCore():getBadHighlitedColor():interp(getCore():getGoodHighlitedColor(), percent, color)
    return "<RGB:" .. color:getR() .. "," .. color:getG() .. "," .. color:getB() .. ">"
end

function RealisticClothes.getUsingThreads(threads, requiredThread)
    local usingThreads = {}
    local totalThreads = 0

    for i = 0, threads:size() - 1 do
        local thread = threads:get(i)
        if totalThreads < requiredThread then
            local remaining = thread:getRemainingUses()
            if remaining > 0 then
                totalThreads = totalThreads + remaining
                table.insert(usingThreads, thread)
            end
        end
    end

    if totalThreads >= requiredThread then
        return usingThreads
    else
        return nil
    end
end

function RealisticClothes.getUsingStrips(strips, requiredStrip)
    local usingStrips = {}

    for i = 0, strips:size() - 1 do
        if #usingStrips < requiredStrip then
            table.insert(usingStrips, strips:get(i))
        end
    end

    if #usingStrips >= requiredStrip then
        return usingStrips
    else
        return nil
    end
end

function RealisticClothes.getUsingPaperclips(paperclips, requiredPaperclip)
    local usingPaperclips = {}

    for i = 0, paperclips:size() - 1 do
        if #usingPaperclips < requiredPaperclip then
            table.insert(usingPaperclips, paperclips:get(i))
        end
    end

    if #usingPaperclips >= requiredPaperclip then
        return usingPaperclips
    else
        return nil
    end
end

function RealisticClothes.addCheckSizeOption(items, player, context)
    local listClothes = {}
    for _, v in ipairs(items) do
        if type(v) == 'table' then
            if v.items and #v.items > 1 then
                for j = 2, #v.items do
                    local e = v.items[j]
                    if instanceof(e, "Clothing") and RealisticClothes.canClothesHaveSize(e) then
                        if not RealisticClothes.hasModData(e) or not RealisticClothes.getOrCreateModData(e).reveal then
                            table.insert(listClothes, e)
                        end
                    end
                end
            end
        else
            if instanceof(v, "Clothing") and RealisticClothes.canClothesHaveSize(v) then
                if not RealisticClothes.hasModData(v) or not RealisticClothes.getOrCreateModData(v).reveal then
                    table.insert(listClothes, v)
                end
            end
        end
    end

    if #listClothes > 0 then
        context:addOption(getText("IGUI_JobType_CheckSize"), player, RealisticClothes.checkClothesSize, listClothes)
    end
end

function RealisticClothes.predicateNeedle(item)
    if item:isBroken() then return false end
    return item:hasTag("Needle") or item:getType() == "Needle"
end

function RealisticClothes.predicateScissors(item)
    if item:isBroken() then return false end
    return item:hasTag("Scissors") or item:getType() == "Scissors"
end

function RealisticClothes.addChangeSizeOption(item, player, context)
    if RealisticClothes.hasModData(item) and not item:isBroken() then
        local data = RealisticClothes.getOrCreateModData(item)
        if data.reveal and data.resized == 0 then
            local nextSize = RealisticClothes.getNextSize(data.size)
            local prevSize = RealisticClothes.getPrevSize(data.size)
            if nextSize or prevSize then
                local tailoring = player:getPerkLevel(Perks.Tailoring)

                local needle = player:getInventory():getFirstEvalRecurse(RealisticClothes.predicateNeedle)
                local scissors = player:getInventory():getFirstEvalRecurse(RealisticClothes.predicateScissors)

                local option = context:addOption(getText("IGUI_JobType_ChangeSize"))
                local subMenu = context:getNew(context)
                context:addSubMenu(option, subMenu)
                if nextSize then
                    local requiredLevel = RealisticClothes.getRequiredLevelToChange(item, true)
                    local requiredThread = RealisticClothes.getRequiredThreadCount(item)
                    local requiredStrip = RealisticClothes.getRequiredStripCount(item)
                    local successChance = RealisticClothes.getSuccessChanceForChange(tailoring, requiredLevel)

                    local threads = player:getInventory():getItemsFromType("Thread", true)
                    local remainingThread = RealisticClothes.getRemainingThread(threads)
                    local fabricType = RealisticClothes.getClothesFabricType(item)
                    local stripType = RealisticClothes.getStripType(fabricType)
                    local strips = player:getInventory():getItemsFromType(stripType, true)

                    local subOption = subMenu:addOption(getText("IGUI_JobType_ToSize", nextSize.name), player, RealisticClothes.upsizeClothes, item, needle, scissors, RealisticClothes.getUsingThreads(threads, requiredThread), RealisticClothes.getUsingStrips(strips, requiredStrip))
                    local tooltip = ISInventoryPaneContextMenu.addToolTip()
                    tooltip.texture = item:getTex()
                    tooltip:setName(getItemNameFromFullType(item:getFullType()) .. " (" .. nextSize.name .. ")")

                    tooltip.description = " " .. RealisticClothes.getColorForPercent(successChance) .. " " .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(successChance * 100) .. "%"
                    tooltip.description = tooltip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
                    tooltip.description = tooltip.description .. " <LINE>" .. (needle ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Needle")
                    tooltip.description = tooltip.description .. " <LINE>" .. (scissors ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Scissors")
                    tooltip.description = tooltip.description .. " <LINE>" .. (remainingThread >= requiredThread and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Thread") .. " " .. remainingThread .. "/" .. requiredThread
                    tooltip.description = tooltip.description .. " <LINE>" .. (strips:size() >= requiredStrip and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType(stripType) .. " " .. strips:size() .. "/" .. requiredStrip
                    tooltip.description = tooltip.description .. " <LINE>" .. (tailoring >= requiredLevel and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. PerkFactory.getPerk(Perks.Tailoring):getName() .. " " .. tailoring .. "/" .. requiredLevel

                    subOption.notAvailable = not (tailoring >= requiredLevel and needle and scissors and remainingThread >= requiredThread and strips:size() >= requiredStrip)
                    subOption.toolTip = tooltip
                end
                if prevSize then
                    local requiredLevel = RealisticClothes.getRequiredLevelToChange(item, false)
                    local requiredThread = RealisticClothes.getRequiredThreadCount(item)
                    local requiredPaperclip = RealisticClothes.getRequiredPaperclip(item)
                    local successChance = RealisticClothes.getSuccessChanceForChange(tailoring, requiredLevel)

                    local threads = player:getInventory():getItemsFromType("Thread", true)
                    local remainingThread = RealisticClothes.getRemainingThread(threads)
                    local paperclips = player:getInventory():getItemsFromType("Paperclip", true)

                    local subOption = subMenu:addOption(getText("IGUI_JobType_ToSize", prevSize.name), player, RealisticClothes.downsizeClothes, item, needle, scissors, RealisticClothes.getUsingThreads(threads, requiredThread), RealisticClothes.getUsingPaperclips(paperclips, requiredPaperclip))
                    local tooltip = ISInventoryPaneContextMenu.addToolTip()
                    tooltip.texture = item:getTex()
                    tooltip:setName(getItemNameFromFullType(item:getFullType()) .. " (" .. prevSize.name .. ")")

                    tooltip.description = " " .. RealisticClothes.getColorForPercent(successChance) .. " " .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(successChance * 100) .. "%"
                    tooltip.description = tooltip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
                    tooltip.description = tooltip.description .. " <LINE>" .. (needle ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Needle")
                    tooltip.description = tooltip.description .. " <LINE>" .. (scissors ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Scissors")
                    tooltip.description = tooltip.description .. " <LINE>" .. (remainingThread >= requiredThread and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Thread") .. " " .. remainingThread .. "/" .. requiredThread
                    tooltip.description = tooltip.description .. " <LINE>" .. (paperclips:size() >= requiredPaperclip and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Paperclip") .. " " .. paperclips:size() .. "/" .. requiredPaperclip
                    tooltip.description = tooltip.description .. " <LINE>" .. (tailoring >= requiredLevel and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. PerkFactory.getPerk(Perks.Tailoring):getName() .. " " .. tailoring .. "/" .. requiredLevel

                    subOption.notAvailable = not (tailoring >= requiredLevel and needle and scissors and remainingThread >= requiredThread and paperclips:size() >= requiredPaperclip)
                    subOption.toolTip = tooltip
                end
            end
        end
    end
end

RealisticClothes.DegradeLocations = {
    Hands = 1, Scarf = 1, Socks = 1, TankTop = 1, Tshirt = 1,
    Torso1 = 2, Legs1 = 2, Shirt = 2, ShortSleeveShirt = 2, TorsoExtra = 2, Pants = 2, Skirt = 2,
    Sweater = 3, SweaterHat = 3, Jacket = 3, Jacket_Down = 3, JacketHat = 3, Torso1Legs1 = 3, BathRobe = 3,
    Jacket_Bulky = 4, JacketHat_Bulky = 4, JacketSuit = 4, Dress = 4,
    FullSuit = 5, Boilersuit = 5, TorsoExtraVest = 5
}

function RealisticClothes.canReconditionClothes(item)
    local location = item:getBodyLocation()
    if not RealisticClothes.DegradeLocations[location] then return false end

    if not RealisticClothes.getClothesFabricType(item) then return false end

    return true
end

function RealisticClothes.canClothesDegrade(item)
    local location = item:getBodyLocation()
    if not RealisticClothes.DegradeLocations[location] then return false end

    local fabricType = RealisticClothes.getClothesFabricType(item)
    if RealisticClothes.OnlyDegradeRepairableClothes and not fabricType then
        return false
    end

    return true
end

function RealisticClothes.calcDegradeChance(item, skillFactor, diffFactor)
    local biteDefense = math.max(0, math.min(100, item:getBiteDefense() or 0.0)) / 100
    local scratchDefense = math.max(0, math.min(100, item:getScratchDefense() or 0.0)) / 100
    local bulletDefense = math.max(0, math.min(100, item:getBulletDefense() or 0.0)) / 100
    local defenseFactor = math.min(0.5, (biteDefense * 4 + bulletDefense * 2 + scratchDefense) / 7) / 0.5
    defenseFactor = 1 - 0.2 * math.sqrt(defenseFactor)          -- 0.8 - 1

    local windResistance = item:getWindresistance() or 0.0      -- 0-1
    local waterResistance = item:getWaterResistance() or 0.0    -- 0-1
    local resistanceFactor = math.min(0.75, (waterResistance + windResistance) / 2) / 0.75
    resistanceFactor = 1 - 0.5 * math.sqrt(resistanceFactor)    -- 0.5 - 1

    local dirty = math.max(0, math.min(100, item:getDirtyness() or 0.0)) / 100
    local blood = math.max(0, math.min(100, item:getBloodLevel() or 0.0)) / 100
    local wet = math.max(0, math.min(100, item:getWetness() or 0.0)) / 100
    local damageFactor = math.max(0, (blood * 4 + wet * 2 + dirty) / 7 - 0.25) / 0.75
    damageFactor = 1 + 0.5 * damageFactor ^ 3                   -- 1 - 1.5

    local totalFactor = damageFactor * defenseFactor * resistanceFactor * skillFactor * diffFactor
    local chance = RealisticClothes.BaseDegradingChance * totalFactor ^ RealisticClothes.DegradingFactorModifier
    RealisticClothes.debugLog(item:getDisplayName() .. string.format(" factor:%.8f", totalFactor) .. string.format(" chance:%.8f", chance))

    return chance
end

function RealisticClothes.getRequiredThreadToRecondition(item, player)
    local requiredThread = RealisticClothes.DegradeLocations[item:getBodyLocation()] * 2
    local threads = player:getInventory():getItemsFromType("Thread", true)

    local usingThreads = {}
    local totalThread = 0
    for i = 0, threads:size() - 1 do
        local thread = threads:get(i)
        local remaining = thread:getRemainingUses()
        if remaining > 0 then
            if totalThread < requiredThread then
                table.insert(usingThreads, thread)
            end
            totalThread = totalThread + remaining
        end
    end

    return requiredThread, totalThread, (totalThread >= requiredThread and usingThreads or nil)
end

function RealisticClothes.getRequiredStripToRecondition(item, player)
    local requiredStrip = RealisticClothes.DegradeLocations[item:getBodyLocation()] * 2

    local fabricType = RealisticClothes.getClothesFabricType(item)
    local stripType = RealisticClothes.getStripType(fabricType)
    local strips = player:getInventory():getItemsFromType(stripType, true)

    local usingStrips = {}
    local totalStrip = 0
    for i = 0, strips:size() - 1 do
        if #usingStrips < requiredStrip then
            table.insert(usingStrips, strips:get(i))
        end
        totalStrip = totalStrip + 1
    end

    return requiredStrip, totalStrip, (totalStrip >= requiredStrip and usingStrips or nil), stripType
end

function RealisticClothes.getReconditionDuration(item)
    return RealisticClothes.DegradeLocations[item:getBodyLocation()] * 20
end

function RealisticClothes.getTailoringXpForRecondition(item, isSuccess)
    local repairedTimes = item:getHaveBeenRepaired() - 1
    local difficulty = RealisticClothes.DegradeLocations[item:getBodyLocation()]

    local xp
    if isSuccess then
        xp = 0.25 * 2^math.max(0, difficulty - repairedTimes)
    else
        xp = 0.2 * difficulty * math.max(0, 10 - repairedTimes) / 10
    end

    return xp * RealisticClothes.TailoringXpMultiplier
end

function RealisticClothes.getPotentialRepairForRecondition(item, player)
    local maintenance = player:getPerkLevel(Perks.Maintenance)
    local tailoring = player:getPerkLevel(Perks.Tailoring)
    local repairedTimes = item:getHaveBeenRepaired() - 1
    local difficulty = RealisticClothes.DegradeLocations[item:getBodyLocation()]

    local delta = tailoring - difficulty + 1
    local potentialRepair = delta >= 0 and ((3 * delta) / (2 + delta) * 0.25) or 0
    potentialRepair = potentialRepair + (6 * maintenance) / (2 + maintenance) * 0.05
    potentialRepair = potentialRepair * 1 / (1 + repairedTimes)
    return math.max(0, math.min(1, potentialRepair))
end

function RealisticClothes.getSuccessChanceForRecondition(item, player)
    local maintenance = player:getPerkLevel(Perks.Maintenance)
    local tailoring = player:getPerkLevel(Perks.Tailoring)
    local repairedTimes = item:getHaveBeenRepaired() - 1
    local difficulty = RealisticClothes.DegradeLocations[item:getBodyLocation()]

    local delta = tailoring - difficulty + 1
    local successChance = delta >= 0 and ((5 * delta) / (1.5 + delta) * 0.25) or (delta * 0.25)
    successChance = successChance + maintenance * 0.05
    if player:HasTrait("Lucky") then successChance = successChance + 0.05 end
    if player:HasTrait("Unlucky") then successChance = successChance - 0.05 end
    successChance = successChance - 0.02 * repairedTimes * (1 + 0.25 * repairedTimes)

    return math.max(0, math.min(1, successChance))
end

function RealisticClothes.addReconditionOption(item, player, context)
    if item:getCondition() == item:getConditionMax() then return end

    local repairedTimes = item:getHaveBeenRepaired() - 1
    local potentialRepair = RealisticClothes.getPotentialRepairForRecondition(item, player)
    local successChance = RealisticClothes.getSuccessChanceForRecondition(item, player)

    local needle = player:getInventory():getFirstEvalRecurse(RealisticClothes.predicateNeedle)
    local requiredThread, remainingThread, threads = RealisticClothes.getRequiredThreadToRecondition(item, player)
    local requiredStrip, remainingStrip, strips, stripType = RealisticClothes.getRequiredStripToRecondition(item, player)

    local option = context:addOption(getText("IGUI_JobType_Recondition"), player, RealisticClothes.reconditionClothes, item, needle, threads, strips, requiredThread)
    option.notAvailable = not (needle and threads and strips)
    option.toolTip = ISInventoryPaneContextMenu.addToolTip()
    option.toolTip.description = " " .. RealisticClothes.getColorForPercent(potentialRepair) .. " " .. getText("Tooltip_potentialRepair") .. " " .. math.ceil(potentialRepair * 100) .. "%"
    option.toolTip.description = option.toolTip.description .. " <LINE> " .. RealisticClothes.getColorForPercent(successChance) .. " " .. getText("Tooltip_chanceSuccess") .. " " .. math.ceil(successChance * 100) .. "%"
    option.toolTip.description = option.toolTip.description .. " <LINE> <LINE> <RGB:1,1,1> " .. getText("Tooltip_craft_Needs") .. ":"
    option.toolTip.description = option.toolTip.description .. " <LINE>" .. (needle ~= nil and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Needle")
    option.toolTip.description = option.toolTip.description .. " <LINE>" .. (remainingThread >= requiredThread and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType("Base.Thread") .. " " .. remainingThread .. "/" .. requiredThread
    option.toolTip.description = option.toolTip.description .. " <LINE>" .. (remainingStrip >= requiredStrip and ISInventoryPaneContextMenu.ghs or ISInventoryPaneContextMenu.bhs) .. getItemNameFromFullType(stripType) .. " " .. remainingStrip .. "/" .. requiredStrip
    option.toolTip.description = option.toolTip.description .. " <LINE> <LINE> <RGB:1,1,0.8> " .. getText("Tooltip_weapon_Repaired") .. ": " .. (repairedTimes == 0 and getText("Tooltip_never") or (repairedTimes .. "x"))
end

function RealisticClothes.reconditionClothes(player, item, needle, threads, strips, threadUses)
    ISInventoryPaneContextMenu.transferIfNeeded(player, needle)
    ISInventoryPaneContextMenu.transferIfNeeded(player, threads)
    ISInventoryPaneContextMenu.transferIfNeeded(player, strips)

    if player:isEquippedClothing(item) then
        ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50))
    else
        ISInventoryPaneContextMenu.transferIfNeeded(player, item)
    end

    ISTimedActionQueue.add(ISReconditionClothes:new(player, item, needle, threads, strips, threadUses))
end