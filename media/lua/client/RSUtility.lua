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
    
    return 40
end

function RealisticShoes.getPlayerSize(player)
    if not player:getModData().RealisticShoes then
        player:getModData().RealisticShoes = {
            size = RealisticClothes.getRandomSize(true, player:isFemale())
        }
    end

    return player:getModData().RealisticShoes.size
end


function RealisticShoes.getOrCreateModData(shoes, size, onChar, isFemale)
    local data = shoes:getModData()
    if not data.RealisticShoes then
        if not size then
            size = RealisticShoes.getRandomSize(onChar, isFemale)
        end

        data.RealisticShoes = {size = size, reveal = false, hint = false}
    end

    return data.RealisticShoes
end