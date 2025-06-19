-- TODO:
-- Stomping damage, stamina, crit
-- Increase trip chance
-- Add tailoring xp

RealisticShoes = RealisticShoes or {}
RealisticShoes.StartingMenSizes = {}
RealisticShoes.StartingWomenSizes = {}
RealisticShoes.NeedTailoringLevel = true
RealisticShoes.TailoringXpMultiplier = 1.0
RealisticShoes.EnableShoesDegrading = true
RealisticShoes.ChanceToDegradeOnFailure = 0.5
RealisticShoes.IncreasePainMultiplier = 1.0
RealisticShoes.Debug = true

function RealisticShoes.onInitMod()
    local startingMenSize = SandboxVars.RealisticShoes.StartingMenSize or 1
    if startingMenSize == 1 then
        RealisticShoes.StartingMenSizes = {42, 43}
    elseif startingMenSize == 2 then
        RealisticShoes.StartingMenSizes = {41, 42, 43, 44}
    elseif startingMenSize == 3 then
        RealisticShoes.StartingMenSizes = {40, 41, 42, 43, 44, 45}
    end

    local startingWomenSize = SandboxVars.RealisticShoes.StartingWomenSize or 1
    if startingWomenSize == 1 then
        RealisticShoes.StartingWomenSizes = {38, 39}
    elseif startingWomenSize == 2 then
        RealisticShoes.StartingWomenSizes = {37, 38, 39, 40}
    elseif startingWomenSize == 3 then
        RealisticShoes.StartingWomenSizes = {36, 37, 38, 39, 40, 41}
    end

    RealisticShoes.NeedTailoringLevel = SandboxVars.RealisticShoes.NeedTailoringLevel
    RealisticShoes.TailoringXpMultiplier = SandboxVars.RealisticShoes.TailoringXpMultiplier or 1.0
    RealisticShoes.EnableShoesDegrading = SandboxVars.RealisticShoes.EnableShoesDegrading
    RealisticShoes.ChanceToDegradeOnFailure = SandboxVars.RealisticShoes.ChanceToDegradeOnFailure or 0.5
    RealisticShoes.IncreasePainMultiplier = SandboxVars.RealisticShoes.IncreasePainMultiplier or 1.0
end
Events.OnInitGlobalModData.Add(RealisticShoes.onInitMod)

function RealisticShoes.onCreatePlayer(playerId)
    local player = getSpecificPlayer(playerId)
    if not player or not player:isLocalPlayer() then return end

    -- first time using this mod
    local shoes = player:getWornItem("Shoes")
    if shoes then
        local size = RealisticShoes.getPlayerSize(player)
        if not RealisticShoes.hasModData(shoes) then
            local data = RealisticShoes.getOrCreateModData(shoes, size)
            data.reveal = true
        end
    end
end
Events.OnCreatePlayer.Add(RealisticShoes.onCreatePlayer)

function RealisticShoes.onUpdatePlayer(player)
    if not player or not player:isLocalPlayer() then return end

    local shoes = player:getWornItem("Shoes")
    if shoes then
        local playerSize = RealisticShoes.getPlayerSize(player)
        local data = RealisticShoes.getOrCreateModData(shoes)
        local diff = data.size - playerSize

        -- tight shoes cause additional pain
        if diff < 0 and player:isPlayerMoving() then
            local mul = 1.0
            if player:isRunning() then
                mul = 2.0
            elseif player:isSprinting() then
                mul = 3.0
            end

            local additionalPain = mul * (math.abs(diff) + 0.5) * RealisticShoes.IncreasePainMultiplier * 0.0025
            local footR = player:getBodyDamage():getBodyPart(BodyPartType.Foot_R)
            local footL = player:getBodyDamage():getBodyPart(BodyPartType.Foot_L)
            footR:setAdditionalPain(footR:getAdditionalPain() + additionalPain * getGameTime():getMultiplier())
            footL:setAdditionalPain(footL:getAdditionalPain() + additionalPain * getGameTime():getMultiplier())
        end

        -- TODO: shoes taking damage from walking on broken glass
        local square = player:getCurrentSquare()
        if square and square:getBrokenGlass() then

        end

        -- TODO: shoes taking damage from walking on corpses
        if square and square:getDeadBody() then

        end

        -- TODO: loose shoes reduce running/sprinting speed (need to sync between clients, move this code to server)
        -- if (player:isRunning() or player:isSprinting()) and not player:isAiming() and not player:isInTreesNoBush() and getCore():getGameMode() ~= "Tutorial" then
        --     -- recalculate move speed
        --     local runSpeedModByBags = 0.0
        --     for i = 0, player:getWornItems():size() - 1 do
        --         local bag = player:getWornItems():getItemByIndex(i)
        --         if instanceof(bag, "InventoryContainer") then
        --             runSpeedModByBags = runSpeedModByBags + player:calcRunSpeedModByBag(bag)
        --         end
        --     end
        --     if player:getPrimaryHandItem() and instanceof(player:getPrimaryHandItem(), "InventoryContainer") then
        --         runSpeedModByBags = runSpeedModByBags + player:calcRunSpeedModByBag(player:getPrimaryHandItem())
        --     end
        --     if player:getSecondaryHandItem() and instanceof(player:getSecondaryHandItem(), "InventoryContainer") then
        --         runSpeedModByBags = runSpeedModByBags + player:calcRunSpeedModByBag(player:getSecondaryHandItem())
        --     end

        --     local speed = (player:calculateBaseSpeed() - 0.15) * (player:getRunSpeedModifier() + runSpeedModByBags) + player:getPerkLevel(Perks.Sprinting) / 20.0
        --     -- speed = speed * RealisticShoes.getSpeedModifier(shoes, player)
        --     -- speed = speed - RealisticShoes.getSpeedModifier(shoes, player)
        --     speed = speed - math.abs(player:getFootInjurySpeedModifier() / 1.5)
        --     if player:getSlowFactor() > 0.0 then speed = speed * 0.05 end
        --     speed = math.min(1, speed)
        --     if player:getBodyDamage() and player:getBodyDamage():getThermoregulator() then
        --         speed = speed * player:getBodyDamage():getThermoregulator():getMovementModifier()
        --     end

        --     player:setVariable("WalkSpeed", speed * getGameTime():getAnimSpeedFix())
        -- end
    end
end
Events.OnPlayerUpdate.Add(RealisticShoes.onUpdatePlayer)

function RealisticShoes.onStompZombie(player, weapon, zombie, damage)
    if not (player and instanceof(player, "IsoPlayer") and player:isLocalPlayer()) then return end
    if not (zombie and instanceof(zombie, "IsoZombie")) then return end
    if not (player:isAimAtFloor() and player:isDoShove() and weapon and weapon:getType() == "BareHands") then return end

    print('RealisticShoes ' .. tostring(damage))

    local shoes = player:getWornItem("Shoes")
    if shoes then
        local playerSize = RealisticShoes.getPlayerSize(player)
        local data = RealisticShoes.getOrCreateModData(shoes)
        local diff = data.size - playerSize

        if diff < 0 then
            local mul = math.abs(diff) + 0.5
            -- stomping on head causes more pain
            if zombie:getHitHeadWhileOnFloor() > 0 then mul = mul * 2.0 end
            -- shoes with higher stomp power will absorb more impact
            mul = mul * math.sqrt(1 / shoes:getStompPower())

            local bodyPart = player:getBodyDamage():getBodyPart(BodyPartType.Foot_R)
            bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + 0.5 * mul * RealisticShoes.IncreasePainMultiplier)
        end
    end
end
Events.OnWeaponHitXp.Add(RealisticShoes.onStompZombie)

function RealisticShoes.onFillInvObjMenu(playerId, context, items)
    local player = getSpecificPlayer(playerId)

    local shoes = nil
    if #items == 1 then
        shoes = items[1]
        if type(shoes) == 'table' then
            if shoes.items and #shoes.items == 2 then
                shoes = shoes.items[2]
            else
                shoes = nil
            end
        end
    end
    if shoes and RealisticShoes.isShoes(shoes) then
        RealisticShoes.addReconditionOption(shoes, player, context)
    end

    RealisticShoes.addCheckSizeOption(items, player, context)
end
Events.OnFillInventoryObjectContextMenu.Add(RealisticShoes.onFillInvObjMenu)

function RealisticShoes.updateShoes()
    local player = getPlayer()
    if not player or not player:isLocalPlayer() then return end

    local shoes = player:getWornItem("Shoes")
    if shoes then
        RealisticShoes.updateShoesByDiff(shoes, player)
    end
end
Events.EveryOneMinute.Add(RealisticShoes.updateShoes)

do -- takes longer to wear tight shoes, can not wear too tight shoes
    local ISWearClothing_new = ISWearClothing.new
    function ISWearClothing:new(character, item, time, ...)
        if not RealisticShoes.isShoes(item) then
            return ISWearClothing_new(self, character, item, time, ...)
        end

        local data = RealisticShoes.getOrCreateModData(item)
        local playerSize = RealisticShoes.getPlayerSize(character)
        local diff = data.size - playerSize

        local timeMultiplier = 1.0
        if diff < 0 then
            timeMultiplier = 1 + 0.25 * 2^(math.abs(diff * 2) - 1)
        else
            timeMultiplier = 1 - 0.05 * diff
        end

        return ISWearClothing_new(self, character, item, time * timeMultiplier, ...)
    end

    local ISWearClothing_perform = ISWearClothing.perform
    function ISWearClothing:perform()
        if not RealisticShoes.isShoes(self.item) then
            return ISWearClothing_perform(self)
        end

        local data = RealisticShoes.getOrCreateModData(self.item)
        local playerSize = RealisticShoes.getPlayerSize(self.character)
        local diff = data.size - playerSize

        if diff < -1 or (not data.reveal and not data.hint) then
            data.hint = true
            self.character:Say(RealisticShoes.getDiffText(diff))

            if diff < -1 then
                self.item:setJobDelta(0.0)
                self.item:getContainer():setDrawDirty(true)
                return
            end
        end

        local result = ISWearClothing_perform(self)
        RealisticShoes.updateShoesByDiff(self.item, self.character)
        return result
    end
end

do -- Reset shoes stats when unequipping
    local ISUnequipAction_perform = ISUnequipAction.perform
    function ISUnequipAction:perform()
        local result = ISUnequipAction_perform(self)

        if RealisticShoes.isShoes(self.item) then
            RealisticShoes.updateShoesByDiff(self.item, self.character)
        end

        return result
    end
end

do -- Handle unequipping shoes when moving them to other containers
    local ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
    function ISInventoryTransferAction:perform()
        if not RealisticShoes.isShoes(self.item) then
            return ISInventoryTransferAction_perform(self)
        end

        if self.srcContainer and self.srcContainer == self.character:getInventory() then
            RealisticShoes.updateShoesByDiff(self.item, self.character)
        end

        -- set all shoes on zombie to the same size of the first clothing initialized
        local srcContainerType = self.srcContainer and self.srcContainer:getType() or ""
        if srcContainerType == 'inventorymale' then
            local size = RealisticShoes.getRandomMenSize()
            RealisticShoes.getOrCreateModData(self.item, size)
        end
        if srcContainerType == 'inventoryfemale' then
            local size = RealisticShoes.getRandomWomenSize()
            RealisticShoes.getOrCreateModData(self.item, size)
        end

        -- shoes transfered to zombie corpes will be initialized first to prevent going through above logic
        local destContainerType = self.destContainer and self.destContainer:getType() or ""
        if destContainerType == 'inventorymale' or destContainerType == 'inventoryfemale' then
            local size = RealisticShoes.getRandomSize(false)
            RealisticShoes.getOrCreateModData(self.item, size)
        end

        return ISInventoryTransferAction_perform(self)
    end
end

if getActivatedMods():contains("RealisticClothes") then
    local RealisticClothes_getAdditionalWeightStr = RealisticClothes.getAdditionalWeightStr
    RealisticClothes.getAdditionalWeightStr = function(player)
        local str = RealisticClothes_getAdditionalWeightStr(player)
        str = str .. ' | ' .. RealisticShoes.getAdditionalWeightStr(player)
        return str
    end
else
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
                local sizeStr = '(' .. RealisticShoes.getAdditionalWeightStr(self.char) .. ')'
                ISCharacterScreen_drawText(self, sizeStr, x + width + 2, y, 1, 1, 1, 1, font or UIFont.Small, ...)
            end
        end
        return ISCharacterScreen_drawText(self, str, x, y, a, b, c, d, font, ...)
    end

    local function drawTexture(self, ...)
        if hasWeightIcon and not hasWeightText then
            hasWeightIcon = false
            -- draw the size label after weight icon
            local sizeStr = '(' .. RealisticShoes.getAdditionalWeightStr(self.char) .. ')'
            ISCharacterScreen_drawText(self, sizeStr, savedX + savedWidth + 18, savedY, 1, 1, 1, 1, savedFont or UIFont.Small, ...)
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

do -- Modify shoes tooltip to include size
    local ISToolTipInv_render = ISToolTipInv.render
    function ISToolTipInv:render()
        if not self.item or not RealisticShoes.isShoes(self.item) then
            return ISToolTipInv_render(self)
        end

        local sizeStr = "???"
        if RealisticShoes.hasModData(self.item) then
            local data = RealisticShoes.getOrCreateModData(self.item)
            local shoesSize = data.size
            local playerSize = RealisticShoes.getPlayerSize(getPlayer())
            local diff = shoesSize - playerSize

            if data.reveal then
                sizeStr = RealisticShoes.getSizeText(shoesSize) .. ' ' .. RealisticShoes.getHintText(diff)
            elseif data.hint then
                sizeStr = RealisticShoes.getHintText(diff)
            end

            if RealisticShoes.Debug then
                sizeStr = sizeStr .. ' [' .. data.size .. '-' .. tostring(data.reveal) .. '-' .. tostring(data.hint) .. ']'
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

do -- Replace display name of inventory items to include shoes size
    local ISInventoryPane_recurIdx = 0
    local Clothing_getName = nil

    local function patchClothingGetName()
        local mt = getmetatable(RealisticShoes.createItem("Base.SpiffoSuit")).__index
        Clothing_getName = mt.getName
        mt.getName = function(self)
            local name = Clothing_getName(self)
            if RealisticShoes.isShoes(self) and RealisticShoes.hasModData(self) then
                local data = RealisticShoes.getOrCreateModData(self)
                if data.reveal then name = name .. ' (' .. RealisticShoes.getSizeText(data.size) .. ')' end
            end
            return name
        end
    end

    local function unpatchClothingGetName()
        local mt = getmetatable(RealisticShoes.createItem("Base.SpiffoSuit")).__index
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