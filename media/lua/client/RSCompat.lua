RealisticShoes = RealisticShoes or {}

function RealisticShoes.getRepairedTimes(item)
    return item:getHaveBeenRepaired() - 1
end

function RealisticShoes.createItem(fullType)
    return InventoryItemFactory.CreateItem(fullType)
end