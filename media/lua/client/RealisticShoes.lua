RealisticShoes = RealisticShoes or {}
RealisticShoes.Debug = true

function RealisticShoes.onInitMod()
end
Events.OnInitGlobalModData.Add(RealisticShoes.onInitMod)

function RealisticShoes.onCreatePlayer(playerId)
    local player = getSpecificPlayer(playerId)
    if not player or not player:isLocalPlayer() then return end

    -- first time using this mod
    local shoes = player:getWornItem("Shoes")
    if shoes then
        local size = RealisticShoes.getPlayerSize(player)
        local data = RealisticShoes.getOrCreateModData(shoes, size)
        if not data.reveal then
            data.reveal = true
        end
    end
end
Events.OnCreatePlayer.Add(RealisticShoes.onCreatePlayer)

function RealisticShoes.onUpdatePlayer(player)

end
Events.OnPlayerUpdate.Add(RealisticShoes.onUpdatePlayer)

function RealisticShoes.onFillInvObjMenu(playerId, context, items)
    local player = getSpecificPlayer(playerId)
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
Events.OnFillInventoryObjectContextMenu.Add(RealisticShoes.onFillInvObjMenu)

do -- Handle unequipping shoes when moving them to other containers
    local ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
    function ISInventoryTransferAction:perform()
        if not RealisticShoes.isShoes(self.item) then
            return ISInventoryTransferAction_perform(self)
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

do  -- Modify character screen to show clothing size according to weight
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
        local mt = getmetatable(InventoryItemFactory.CreateItem("Base.SpiffoSuit")).__index
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
        local mt = getmetatable(InventoryItemFactory.CreateItem("Base.SpiffoSuit")).__index
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