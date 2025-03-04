local mod = RegisterMod("MyMod", 1)

local redButton = Isaac.GetItemIdByName("The Button")
function mod:RedButtonUse()
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            entity:Kill()
        end
    end
    return true -- Correct return for MC_USE_ITEM
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, redButton)
