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
        local data = RealisticShoes.getOrCreateModData(shoes, size, true, player:isFemale())
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
                    if instanceof(e, "Clothing") and e:getBodyLocation() == "Shoes" then
                        if not RealisticShoes.hasModData(e) or not RealisticShoes.getOrCreateModData(e).reveal then
                            table.insert(listShoes, e)
                        end
                    end
                end
            end
        else
            if instanceof(v, "Clothing") and v:getBodyLocation() == "Shoes" then
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

do -- Modify shoes tooltip to include size
    local ISToolTipInv_render = ISToolTipInv.render
    function ISToolTipInv:render()
        if not self.item or not instanceof(self.item, "Clothing") or not self.item:getBodyLocation() == "Shoes" then
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
            if self:getBodyLocation() == "Shoes" and RealisticShoes.hasModData(self) then
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