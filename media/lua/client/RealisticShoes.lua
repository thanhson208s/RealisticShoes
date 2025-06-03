RealisticShoes = RealisticShoes or {}

function RealisticClothes.onInitMod()
end
Events.OnInitGlobalModData.Add(RealisticClothes.onInitMod)

function RealisticClothes.onCreatePlayer(playerId)
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
Events.OnCreatePlayer.Add(RealisticClothes.onCreatePlayer)