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
    {size=40, chance=8},
    {size=41, chance=12},
    {size=42, chance=24},
    {size=43, chance=26},
    {size=44, chance=20},
    {size=45, chance=10}
}

RealisticShoes.WOMEN_SIZES = {
    {size=36, chance=14},
    {size=37, chance=20},
    {size=38, chance=28},
    {size=39, chance=22},
    {size=40, chance=12},
    {size=41, chance=4}
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
    if not player:getModData().RealisticShoes then
        player:getModData().RealisticShoes = {
            size = RealisticShoes.getRandomSize(true, player:isFemale())
        }
    end

    return player:getModData().RealisticShoes.size
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
        text = getText("IGUI_Say_Shoes_Too_Tight")
    elseif diff == -1 then
        text = getText("IGUI_Say_Shoes_Tight")
    elseif diff < 0 then
        text = getText("IGUI_Say_Shoes_Slightly_Tight")
    elseif diff == 0 then
        text = getText("IGUI_Say_Shoes_Fit")
    elseif diff < 1 then
        text = getText("IGUI_Say_Shoes_Slightly_Loose")
    elseif diff == 1 then
        text = getText("IGUI_Say_Shoes_Loose")
    else
        text = getText("IGUI_Say_Shoes_Too_Loose")
    end

    if size ~= nil then
        text = RealisticShoes.getSizeText(size) .. '. ' .. text
    end

    return text
end

function RealisticShoes.isShoes(item)
    return instanceof(item, "Clothing") and item:getBodyLocation() == "Shoes"
end

function RealisticShoes.checkShoesSize(player, items)
    local inv = player:getInventory()
    for i, item in ipairs(items) do
        local container = item:getContainer()
        if container and container ~= inv then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, container, inv))
        end
        ISTimedActionQueue.add(ISCheckShoesSize:new(player, item, 50))
    end
end

function RealisticShoes.getAdditionalWeightStr(player)
    local extraSize = RealisticShoes.getPlayerExtraSize(player)

    return 'EU ' .. RealisticShoes.getPlayerOriginalSize(player) .. (extraSize > 0 and ('+' .. extraSize) or '')
end