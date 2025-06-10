RealisticShoes = RealisticShoes or {}

function RealisticShoes.getRepairedTimes(item)
    return item:getHaveBeenRepaired()
end

function RealisticShoes.createItem(fullType)
    return instanceItem(fullType)
end