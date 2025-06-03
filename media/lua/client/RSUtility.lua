RealisticShoes = RealisticShoes or {}

RealisticShoes.SIZES = {
    [36] = 6,
    [37] = 8,
    [38] = 12,
    [39] = 13,
    [40] = 14,
    [41] = 13,
    [42] = 12,
    [43] = 10,
    [44] = 7,
    [45] = 5
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