local mod = PBK
local redButton = Isaac.GetItemIdByName("The Button")

function mod:RedButtonUse(item, rng, player, useFlags, activeSlot, customVarData)
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            entity:Kill()
        end
    end

    -- Remove the item from the player's inventory (one-time use)
    player:RemoveCollectible(redButton)

    return true -- Indicates the item was successfully used
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, redButton)
