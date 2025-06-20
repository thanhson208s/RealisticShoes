RealisticShoes = RealisticShoes or {}

function RealisticShoes.getRepairedTimes(item)
    return item:getHaveBeenRepaired() - 1
end

function RealisticShoes.createItem(fullType)
    return InventoryItemFactory.CreateItem(fullType)
end

function RealisticShoes.predicateScissors(item)
    if item:isBroken() then return false end
    return item:getType() == "Scissors"
end

function RealisticShoes.getUseCount(item)
    return item and 1 or 0
end

RealisticShoes.RepairOptions = {
    ["Base.Glue"] = 2,
    ["Base.DuctTape"] = 2,
    ["Base.Scotchtape"] = 2
}