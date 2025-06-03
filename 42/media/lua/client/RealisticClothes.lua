RealisticClothes = RealisticClothes or {}
RealisticClothes.NeedTailoringLevel = true
RealisticClothes.TailoringXpMultiplier = 1.0
RealisticClothes.RipChanceMultiplier = 1.0
RealisticClothes.DropChanceMultiplier = 1.0
RealisticClothes.InsulationReduceMultiplier = 1.0
RealisticClothes.CombatSpeedReduceMultiplier = 1.0
RealisticClothes.IncreaseTripChanceMultiplier = 1.0
RealisticClothes.IncreaseStiffnessMultiplier = 1.0
RealisticClothes.EnableClothesDegrading = true
RealisticClothes.OnlyDegradeRepairableClothes = false
RealisticClothes.BaseDegradingChance = 0.0
RealisticClothes.DegradingFactorModifier = 1.0
RealisticClothes.ChanceToDegradeOnFailure = 0.5
RealisticClothes.Debug = false

-- Init all modifiers
function RealisticClothes.onInitMod()
    RealisticClothes.NeedTailoringLevel = SandboxVars.RealisticClothes.NeedTailoringLevel
    RealisticClothes.TailoringXpMultiplier = SandboxVars.RealisticClothes.TailoringXpMultiplier or 1.0
    RealisticClothes.RipChanceMultiplier = SandboxVars.RealisticClothes.RipChanceMultiplier or 1.0
    RealisticClothes.DropChanceMultiplier = SandboxVars.RealisticClothes.DropChanceMultiplier or 1.0
    RealisticClothes.InsulationReduceMultiplier = SandboxVars.RealisticClothes.InsulationReduceMultiplier or 1.0
    RealisticClothes.CombatSpeedReduceMutiplier = SandboxVars.RealisticClothes.CombatSpeedReduceMultiplier or 1.0
    RealisticClothes.IncreaseTripChanceMultiplier = SandboxVars.RealisticClothes.IncreaseTripChanceMultiplier or 1.0
    RealisticClothes.IncreaseStiffnessMultiplier = SandboxVars.RealisticClothes.IncreaseStiffnessMultiplier or 1.0
    RealisticClothes.EnableClothesDegrading = SandboxVars.RealisticClothes.EnableClothesDegrading
    RealisticClothes.OnlyDegradeRepairableClothes = SandboxVars.RealisticClothes.OnlyDegradeRepairableClothes
    RealisticClothes.ChanceToDegradeOnFailure = SandboxVars.RealisticClothes.ChanceToDegradeOnFailure or 0.5
    
    local minDaysToDegrade = SandboxVars.RealisticClothes.MinDaysToDegrade or 30
    local maxDaysToDegrade = SandboxVars.RealisticClothes.MaxDaysToDegrade or 360
    if minDaysToDegrade > maxDaysToDegrade then
        minDaysToDegrade = 30
        maxDaysToDegrade = 360
    end

    local maxChance = 10 / (minDaysToDegrade * 24)
    local minChance = 10 / (maxDaysToDegrade * 24)
    RealisticClothes.DegradingFactorModifier = math.log(maxChance / minChance) / math.log(2.25 / 0.2)
    RealisticClothes.BaseDegradingChance = math.sqrt(minChance * maxChance / (0.2 * 2.25) ^ RealisticClothes.DegradingFactorModifier)
end
Events.OnInitGlobalModData.Add(RealisticClothes.onInitMod)

-- Add option to check label to item context menu
function RealisticClothes.onFillInvObjMenu(playerId, context, items)
    local player = getSpecificPlayer(playerId)

    local clothingItem = nil
    if #items == 1 then
        clothingItem = items[1]
        if type(clothingItem) == 'table' then
            if clothingItem.items and #clothingItem.items == 2 then
                clothingItem = clothingItem.items[2]
            else
                clothingItem = nil
            end
        end
    end
    if clothingItem and instanceof(clothingItem, "Clothing") then
        if RealisticClothes.canResizeClothes(clothingItem) then
            RealisticClothes.addChangeSizeOption(clothingItem, player, context)
        end

        if RealisticClothes.canReconditionClothes(clothingItem) then
            RealisticClothes.addReconditionOption(clothingItem, player, context)
        end

        RealisticClothes.debugLog('condition: ' .. tostring(clothingItem:getCondition()) .. '|' .. tostring(clothingItem:getConditionMax()))
        RealisticClothes.debugLog('insulation: ' .. tostring(clothingItem:getInsulation()) .. '|' .. tostring(RealisticClothes.getOriginalInsulation(clothingItem)))
        RealisticClothes.debugLog('combat speed modifier: ' .. tostring(clothingItem:getCombatSpeedModifier()) .. '|' .. tostring(RealisticClothes.getOriginalCombatSpeedModifier(clothingItem)))
    end

    RealisticClothes.addCheckSizeOption(items, player, context)
end
Events.OnFillInventoryObjectContextMenu.Add(RealisticClothes.onFillInvObjMenu)

-- Init all clothes's stats when creating player
function RealisticClothes.onCreatePlayer(playerId)
    local player = getSpecificPlayer(playerId)
    if not player or not player:isLocalPlayer() then return end

    -- first time using this mod, init all clothes that already on player
    local list = player:getWornItems()
    local sizeName = RealisticClothes.getPlayerSize(player).name
    for i = 0, list:size() - 1 do
        local item = list:getItemByIndex(i)
        if item and RealisticClothes.canClothesHaveSize(item) then
            local data = RealisticClothes.getOrCreateModData(item, sizeName)
            data.hint = true
        end
    end

    RealisticClothes.updateAllClothes(player)
end
Events.OnCreatePlayer.Add(RealisticClothes.onCreatePlayer)

-- Reduce the rate of stiffness recovering if player is wearing tight clothes
function RealisticClothes.onUpdatePlayer(player)
    if not player or not player:isLocalPlayer() then return end

    if player:getFitness() and not player:getFitness():onGoingStiffness() then
        local allBodyParts = player:getBodyDamage():getBodyParts()
        for i = 0, allBodyParts:size() - 1 do
            local bodyPart = allBodyParts:get(i)
            if bodyPart:getStiffness() > 0 then
                local diff = RealisticClothes.getDiffForBodyPart(player, bodyPart:getType())
                if diff < 0 then
                    local extraStiffness = (bodyPart:getStiffness() < 5 * math.abs(diff)) and 0.002 or (math.abs(diff) * 0.0005)
                    bodyPart:setStiffness(bodyPart:getStiffness() + extraStiffness * getGameTime():getMultiplier())
                end
            end
        end
    end
end
Events.OnPlayerUpdate.Add(RealisticClothes.onUpdatePlayer)

-- Update all clothes's stats every one minute
function RealisticClothes.onUpdateClothes()
    local player = getPlayer()
    if not player or not player:isLocalPlayer() then return end

    RealisticClothes.updateAllClothes(player)
end
Events.EveryOneMinute.Add(RealisticClothes.onUpdateClothes)

-- Extra trip chance and chance to rip clothes when climbing
function RealisticClothes.onPlayerClimb(player, state)
    if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then return end
    if not state then return end

    local baseRipChance = 0
    if instanceof(state, "ClimbOverWallState") then
        baseRipChance = 0.01      -- 1% when climbing over high fence
    elseif instanceof(state, "ClimbThroughWindowState") then
        baseRipChance = 0.002       -- 0.2% when climbing though window
    elseif instanceof(state, "ClimbOverFenceState") then
        if player:getVariableBoolean("VaultOverRun") then
            baseRipChance = 0.004   -- 0.4% when vaulting fence while running
        elseif player:getVariableBoolean("VaultOverSprint") then
            baseRipChance = 0.005   -- 0.5% when vaulting fence while sprinting
        else
            baseRipChance = 0.001   -- 0.1% when climb fence
        end
    end

    local playerSize = RealisticClothes.getPlayerSize(player)
    local list = player:getWornItems()
    local extraTripChance = 0
    for i = 0, list:size() - 1 do
        local item = list:getItemByIndex(i)
        if item and RealisticClothes.canClothesHaveSize(item) then
            local data = RealisticClothes.getOrCreateModData(item)
            local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
            local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)

            if RealisticClothes.canClothesRip(item) and diff < 0 and baseRipChance > 0 then
                if ZombRandFloat(0, 1) < baseRipChance * RealisticClothes.getClothesRipChance(diff) then
                    if RealisticClothes.ripClothes(item, player) then 
                        baseRipChance = baseRipChance / 2   -- make it less likely to rip again in the same action
                    end
                end
            end

            if RealisticClothes.doesClothesIncreaseTrip(item) and diff > 0 then
                extraTripChance = extraTripChance + RealisticClothes.getExtraTripChance(diff)
            end
        end
    end

    -- Add extra trip chance when vaulting fence while running or sprinting in loose clothes
    if instanceof(state, "ClimbOverFenceState") and extraTripChance > 0 then
        local outcome = player:getVariableString("ClimbFenceOutcome")
        if outcome ~= "lunge" and outcome ~= "falling" and outcome ~= "rope" then
            if player:getVariableBoolean("VaultOverRun") or player:getVariableBoolean("VaultOverSprint") then
                local tripChance = player:getVariableBoolean("VaultOverSprint") and 10 or 0

                if player:getMoodles() then
                    tripChance = tripChance + player:getMoodles():getMoodleLevel(MoodleType.Pain) * 5
                    tripChance = tripChance + player:getMoodles():getMoodleLevel(MoodleType.Endurance) * 10;
                    tripChance = tripChance + player:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) * 13;
                end

                local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.Torso_Lower)
                if bodyPart and bodyPart:getAdditionalPain(true) > 20.0 then
                    tripChance = tripChance + (bodyPart:getAdditionalPain(true) - 20.0) / 10.0
                end

                if player:HasTrait("Clumsy") then tripChance = tripChance + 10 end
                if player:HasTrait("Graceful") then tripChance = tripChance - 10 end
                if player:HasTrait("VeryUnderweight") then tripChance = tripChance + 20 end
                if player:HasTrait("Underweight") then tripChance = tripChance + 10 end
                if player:HasTrait("Obese") then tripChance = tripChance + 20 end
                if player:HasTrait("Overweight") then tripChance = tripChance + 10 end

                -- extra trip chance added here, all others are from original formula
                tripChance = tripChance + extraTripChance

                tripChance = tripChance - player:getPerkLevel(Perks.Fitness)
                if ZombRand(100) < tripChance then
                    player:setVariable("ClimbFenceOutcome", "fall")
                end
            end
        end
    end
end
Events.OnAIStateChange.Add(RealisticClothes.onPlayerClimb)

function RealisticClothes.checkClothesCondition()
    if not RealisticClothes.EnableClothesDegrading then return end

    local player = getPlayer()
    if not player or not player:isLocalPlayer() then return end
    local playerSize = RealisticClothes.getPlayerSize(player)
    local maintenance = player:getPerkLevel(Perks.Maintenance)  -- 0-10
    local tailoring = player:getPerkLevel(Perks.Tailoring)      -- 0-10
    local skillFactor = 1 - math.sqrt((maintenance * 2 + tailoring) / 3) / 2    -- 0.5 - 1

    local items = player:getWornItems()
    for i = 0, items:size() - 1 do
        local item = items:getItemByIndex(i)
        if item and instanceof(item, "Clothing") and RealisticClothes.canClothesDegrade(item) then
            local diff = 0
            if RealisticClothes.canClothesHaveSize(item) then
                local data = RealisticClothes.getOrCreateModData(item)
                local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
                diff = math.max(-2, math.min(0, RealisticClothes.getSizeDiff(clothesSize, playerSize)))
            end
            local diffFactor = 0.5 + 2 / (4 + diff)     -- 1 - 1.5

            local chance = RealisticClothes.calcDegradeChance(item, skillFactor, diffFactor)
            if ZombRandFloat(0, 1) < chance then
                item:setCondition(item:getCondition() - 1)
                HaloTextHelper.addTextWithArrow(player, item:getScriptItem():getDisplayName(), false, HaloTextHelper.getColorRed())

                if item:getCondition() <= 0 then
                    player:getEmitter():playSound("PutItemInBag")
                end
            end
        end
    end
end
Events.EveryHours.Add(RealisticClothes.checkClothesCondition)

do -- Add extra stiffness for every fitness rep when wearing tight clothes
    local ISFitnessAction_exeLooped = ISFitnessAction.exeLooped
    function ISFitnessAction:exeLooped()
        ISFitnessAction_exeLooped(self)

        local bodyPartTypes = {}
        local regions = luautils.split(self.exeData.stiffness, ',')
        for _, region in ipairs(regions) do
            if region == 'arms' then
                table.insert(bodyPartTypes, BodyPartType.ForeArm_L)
                table.insert(bodyPartTypes, BodyPartType.ForeArm_R)
                table.insert(bodyPartTypes, BodyPartType.UpperArm_L)
                table.insert(bodyPartTypes, BodyPartType.UpperArm_R)
            elseif region == 'legs' then
                table.insert(bodyPartTypes, BodyPartType.UpperLeg_L)
                table.insert(bodyPartTypes, BodyPartType.UpperLeg_R)
                table.insert(bodyPartTypes, BodyPartType.LowerLeg_L)
                table.insert(bodyPartTypes, BodyPartType.LowerLeg_R)
            elseif region == 'chest' then
                table.insert(bodyPartTypes, BodyPartType.Torso_Upper)
            elseif region == 'abs' then
                table.insert(bodyPartType, BodyPartType.Torso_Lower)
            end
        end

        for _, bodyPartType in ipairs(bodyPartTypes) do
            local bodyPart = self.character:getBodyDamage():getBodyPart(bodyPartType)
            local diff = RealisticClothes.getDiffForBodyPart(self.character, bodyPartType)
            if diff < 0 then
                bodyPart:setStiffness(bodyPart:getStiffness() + RealisticClothes.getExtraStiffness(diff))
            end
        end
    end
end

do -- Adjust the time it takes to wear clothing based on size difference
    local ISWearClothing_new = ISWearClothing.new
    function ISWearClothing:new(character, item, time, ...)
        if not RealisticClothes.canClothesHaveSize(item) then 
            return ISWearClothing_new(self, character, item, time, ...)
        end

        local data = RealisticClothes.getOrCreateModData(item)
        local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
        local playerSize = RealisticClothes.getPlayerSize(character)
        local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)

        local timeMultiplier = 1.0
        if diff < 0 then        -- the smaller the clothing, the longer it takes to wear
            timeMultiplier = 1 + 0.25 * 2^(math.abs(diff) - 1)
        elseif diff > 0 then    -- the bigger the clothing, the shorter it takes to wear
            timeMultiplier = 1 - 0.1 * diff
        end

        return ISWearClothing_new(self, character, item, time * timeMultiplier, ...)
    end
end

do -- Chance to rip too tight clothing when wearing, can not wear very tight clothing
    local ISWearClothing_perform = ISWearClothing.perform
    function ISWearClothing:perform()
        if not RealisticClothes.canClothesHaveSize(self.item) then 
            return ISWearClothing_perform(self)
        end

        local data = RealisticClothes.getOrCreateModData(self.item)
        local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
        local playerSize = RealisticClothes.getPlayerSize(self.character)
        local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)

        if diff < -2 or (not data.reveal and not data.hint) then
            data.hint = true    -- player can guess approximately the size of the clothing
            self.character:Say(RealisticClothes.getHintFromSizeDiff(diff))

            if diff < -2 then
                self.item:setJobDelta(0.0)
                self.item:getContainer():setDrawDirty(true)
                return
            end
        end
        
        local result = ISWearClothing_perform(self)
        RealisticClothes.updateOneClothes(self.item, self.character)
        return result
    end
end

do -- Keep clothing size when creating new clothing variants (hood up, hood down, etc.)
    local ISClothingExtraAction_createItem = ISClothingExtraAction.createItem
    function ISClothingExtraAction:createItem(oldItem, itemType, ...)
        local newItem =  ISClothingExtraAction_createItem(self, oldItem, itemType, ...)
        if instanceof(oldItem, "Clothing") and RealisticClothes.canClothesHaveSize(oldItem) and instanceof(newItem, "Clothing") and RealisticClothes.canClothesHaveSize(newItem) then
            local oldData = RealisticClothes.getOrCreateModData(oldItem)
            local newData = RealisticClothes.getOrCreateModData(newItem)
            newData.size = oldData.size
            newData.reveal = oldData.reveal
            newData.hint = oldData.hint
            newData.resized = oldData.resized
        end

        return newItem
    end
end

do -- Reset clothing stats when unequipping
    local ISUnequipAction_perform = ISUnequipAction.perform
    function ISUnequipAction:perform()
        local result = ISUnequipAction_perform(self)

        if instanceof(self.item, "Clothing") and RealisticClothes.canClothesHaveSize(self.item) then
            RealisticClothes.updateOneClothes(self.item, self.character)
        end

        return result
    end
end

do -- Handle unequipping clothes when moving them to other containers
    local ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
    function ISInventoryTransferAction:perform()
        if not instanceof(self.item, "Clothing") or not RealisticClothes.canClothesHaveSize(self.item) then
            return ISInventoryTransferAction_perform(self)
        end

        -- clothes are unequiped when transfered to a container
        if self.srcContainer and self.srcContainer == self.character:getInventory() then
            RealisticClothes.updateOneClothes(self.item, self.character)
        end

        -- set all clothes on zombie to the same size of the first clothing initialized
        local srcContainerType = self.srcContainer and self.srcContainer:getType() or ""
        if srcContainerType == 'inventorymale' or srcContainerType == 'inventoryfemale' then
            local sizeName = RealisticClothes.getRandomClothesSize().name
            local allClothes = self.srcContainer:getItemsFromCategory("Clothing")
            for i = 0, allClothes:size() - 1 do
                local item = allClothes:get(i)
                if instanceof(item, "Clothing") and RealisticClothes.canClothesHaveSize(item) then
                    local data = RealisticClothes.getOrCreateModData(item, sizeName)
                end
            end
        end

        -- clothes transfered to zombie corpes will be initialized first to prevent going through above logic
        local destContainerType = self.destContainer and self.destContainer:getType() or ""
        if destContainerType == 'inventorymale' or destContainerType == 'inventoryfemale' then
            RealisticClothes.getOrCreateModData(self.item)
        end

        return ISInventoryTransferAction_perform(self)
    end
end

do -- Disable condition gain/loss when adding/removing patches
    local ISRepairClothing_perform = ISRepairClothing.perform
    function ISRepairClothing:perform()
        if not RealisticClothes.EnableClothesDegrading or not RealisticClothes.canClothesDegrade(self.clothing) then
            return ISRepairClothing_perform(self)
        end

        local cond = self.clothing:getCondition()
        ISRepairClothing_perform(self)
        self.clothing:setCondition(cond)
    end

    local ISRemovePatch_perform = ISRemovePatch.perform
    function ISRemovePatch:perform()
        if not RealisticClothes.EnableClothesDegrading or not RealisticClothes.canClothesDegrade(self.clothing) then
            return ISRemovePatch_perform(self)
        end

        local cond = self.clothing:getCondition()
        ISRemovePatch_perform(self)
        self.clothing:setCondition(cond)
    end
end

do -- Modify character screen to show clothing size according to weight
    local ISCharacterScreen_drawTextRight = ISCharacterScreen.drawTextRight
    local ISCharacterScreen_drawText = ISCharacterScreen.drawText
    local ISCharacterScreen_drawTexture = ISCharacterScreen.drawTexture
    local ISCharacterScreen_isRedendering = false
    local hasWeightText = false
    local hasWeightIcon = false
    local savedWidth, savedX, savedY, savedFont

    -- when draw the weight label
    local function drawTextRight(self, str, x, y, ...)
        if str == getText("IGUI_char_Weight") then
            hasWeightText = true
            local nutrition = self.char:getNutrition()
            if nutrition:isIncWeight() or nutrition:isIncWeightLot() or nutrition:isDecWeight() then
                hasWeightIcon = true
            end
        end
        return ISCharacterScreen_drawTextRight(self, str, x, y, ...)
    end

    -- when draw the weight value
    local function drawText(self, str, x, y, a, b, c, d, font, ...)
        if hasWeightText then
            hasWeightText = false
            local width = getTextManager():MeasureStringX(UIFont.Small, str)
            
            if hasWeightIcon then
                savedWidth = width
                savedX = x
                savedY = y
                savedFont = font
            else
                -- draw the size label after weight value
                local sizeStr = '(' .. RealisticClothes.getPlayerSize(self.char).name .. ')'
                ISCharacterScreen_drawText(self, sizeStr, x + width + 2, y, 1, 1, 1, 1, font or UIFont.Small, ...)
            end
        end
        return ISCharacterScreen_drawText(self, str, x, y, a, b, c, d, font, ...)
    end

    local function drawTexture(self, ...)
        if hasWeightIcon and not hasWeightText then
            hasWeightIcon = false
            -- draw the size label after weight icon
            local sizeStr = '(' .. RealisticClothes.getPlayerSize(self.char).name .. ')'
            ISCharacterScreen_drawText(self, sizeStr, savedX + savedWidth + 17, savedY, 1, 1, 1, 1, savedFont or UIFont.Small, ...)
        end
        return ISCharacterScreen_drawTexture(self, ...)
    end

    local ISCharacterScreen_render = ISCharacterScreen.render
    function ISCharacterScreen:render()
        if ISCharacterScreen_isRedendering then
            if ISCharacterScreen_drawTextRight and self.drawTextRight == drawTextRight then
                self.drawTextRight = ISCharacterScreen_drawTextRight
            end
            if ISCharacterScreen_drawText and self.drawText == drawText then
                self.drawText = ISCharacterScreen_drawText
            end
            if ISCharacterScreen_drawTexture and self.drawTexture == drawTexture then
                self.drawTexture = ISCharacterScreen_drawTexture
            end
            return ISCharacterScreen_render(self)
        end

        hasWeightText = false
        hasWeightIcon = false
        ISCharacterScreen_drawTextRight = self.drawTextRight
        self.drawTextRight = drawTextRight
        ISCharacterScreen_drawText = self.drawText
        self.drawText = drawText
        ISCharacterScreen_drawTexture = self.drawTexture
        self.drawTexture = drawTexture

        ISCharacterScreen_isRedendering = true
        local ok, result = pcall(ISCharacterScreen_render, self)
        ISCharacterScreen_isRedendering = false

        if ISCharacterScreen_drawTextRight then
            self.drawTextRight = ISCharacterScreen_drawTextRight
        end
        if ISCharacterScreen_drawText then
            self.drawText = ISCharacterScreen_drawText
        end
        if ISCharacterScreen_drawTexture then
            self.drawTexture = ISCharacterScreen_drawTexture
        end

        if not ok then error('Unexpected error in ISCharacterScreen:render() - ' .. result) end

        return result
    end
end

do -- Modify clothes tooltip to include size
    local ISToolTipInv_render = ISToolTipInv.render
    function ISToolTipInv:render()
        if not self.item or not instanceof(self.item, "Clothing") or not RealisticClothes.canClothesHaveSize(self.item) then
            return ISToolTipInv_render(self)
        end
                
        local sizeStr = '???'
        
        if RealisticClothes.hasModData(self.item) then
            local data = RealisticClothes.getOrCreateModData(self.item)
            local clothesSize = RealisticClothes.getClothesSizeFromName(data.size)
            local playerSize = RealisticClothes.getPlayerSize(getPlayer())
            local diff = RealisticClothes.getSizeDiff(clothesSize, playerSize)

            if data.reveal then
                sizeStr = clothesSize.name .. (data.resized ~= 0 and '*' or '') .. ' ' .. RealisticClothes.getHintText(diff)
            elseif data.hint then
                sizeStr = RealisticClothes.getHintText(diff)
            end

            if RealisticClothes.Debug then
                sizeStr = sizeStr .. ' [' .. tostring(data.size) .. '-' .. tostring(data.reveal) .. '-' .. tostring(data.hint) .. '-' .. tostring(data.resized) .. ']'
            end
        end

        local injectionStage = 1
        local originalHeight

        local oldSetHeight = self.setHeight
        self.setHeight = function(self, height, ...)
            if injectionStage == 1 then
                injectionStage = 2
                originalHeight = height
                height = height + 18
            end
            return oldSetHeight(self, height, ...)
        end

        local oldDrawRectBorder = self.drawRectBorder
        self.drawRectBorder = function(self, ...)
            if injectionStage == 2 then
                injectionStage = 3
                self.tooltip:DrawText(
                    UIFont[getCore():getOptionTooltipFont()],
                    sizeStr, 5, originalHeight - 5,
                    1, 1, 1, 1
                )
            end
            return oldDrawRectBorder(self, ...)
        end

        local result = ISToolTipInv_render(self)

        self.setHeight = oldSetHeight
        self.drawRectBorder = oldDrawRectBorder

        return result
    end
end

do -- Replace display name of inventory items to include clothes size
    local ISInventoryPane_recurIdx = 0
    local Clothing_getName = nil

    local function patchClothingGetName()
        local mt = getmetatable(instanceItem("Base.SpiffoSuit")).__index
        Clothing_getName = mt.getName
        mt.getName = function(self)
            local name = Clothing_getName(self)
            if RealisticClothes.canClothesHaveSize(self) and RealisticClothes.hasModData(self) then
                local data = RealisticClothes.getOrCreateModData(self)
                if data.reveal then name = name .. ' (' .. data.size .. ')' end
            end
            return name
        end
    end

    local function unpatchClothingGetName()
        local mt = getmetatable(instanceItem("Base.SpiffoSuit")).__index
        mt.getName = Clothing_getName
        Clothing_getName = nil
    end

    local ISInventoryPane_renderdetails = ISInventoryPane.renderdetails
    function ISInventoryPane:renderdetails(doDragged)
        if ISInventoryPane_recurIdx == 0 and not Clothing_getName then
            patchClothingGetName()
        end

        ISInventoryPane_recurIdx = ISInventoryPane_recurIdx + 1
        local result = ISInventoryPane_renderdetails(self, doDragged)
        ISInventoryPane_recurIdx = ISInventoryPane_recurIdx - 1

        if ISInventoryPane_recurIdx == 0 and Clothing_getName then
            unpatchClothingGetName()
        end

        return result
    end

    local ISInventoryPane_refreshContainer = ISInventoryPane.refreshContainer
    function ISInventoryPane:refreshContainer()
        if ISInventoryPane_recurIdx == 0 and not Clothing_getName then
            patchClothingGetName()
        end

        ISInventoryPane_recurIdx = ISInventoryPane_recurIdx + 1
        local result = ISInventoryPane_refreshContainer(self)
        ISInventoryPane_recurIdx = ISInventoryPane_recurIdx - 1

        if ISInventoryPane_recurIdx == 0 and Clothing_getName then
            unpatchClothingGetName()
        end

        return result
    end

    local ISInventoryPane_drawItemDetails = ISInventoryPane.drawItemDetails
    function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)
        if ISInventoryPane_recurIdx == 0 and not Clothing_getName then
            patchClothingGetName()
        end

        ISInventoryPane_recurIdx = ISInventoryPane_recurIdx + 1
        local result = ISInventoryPane_drawItemDetails(self, item, y, xoff, yoff, red)
        ISInventoryPane_recurIdx = ISInventoryPane_recurIdx - 1

        if ISInventoryPane_recurIdx == 0 and Clothing_getName then
            unpatchClothingGetName()
        end

        return result
    end
end