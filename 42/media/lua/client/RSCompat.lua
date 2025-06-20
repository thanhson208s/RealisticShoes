RealisticShoes = RealisticShoes or {}

function RealisticShoes.getRepairedTimes(item)
    return item:getHaveBeenRepaired()
end

function RealisticShoes.createItem(fullType)
    return instanceItem(fullType)
end

function RealisticShoes.predicateScissors(item)
    if item:isBroken() then return false end
    return item:hasTag("Scissors")
end

function RealisticShoes.getUseCount(item)
    return item:getCurrentUses()
end

RealisticShoes.RepairOptions = {
    ["Base.Glue"] = 2,
    ["Base.DuctTape"] = 2,
    ["Base.Epoxy"] = 2
}