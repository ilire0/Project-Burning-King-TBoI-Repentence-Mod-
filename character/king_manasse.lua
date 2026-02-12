local mod = RegisterMod("PBK", 1)
require("items.purgatory_flame")
local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")
local PURGATORY_FLAME = Isaac.GetItemIdByName("Purgatory Flame")

function mod:OnGabrielInit(player)
    if player:GetPlayerType() == gabrielType then
        player:AddNullCostume(hairCostume)
        player:AddNullCostume(stolesCostume)
        player:AddCollectible(PURGATORY_FLAME, 0, true)
        player:FullCharge(ActiveSlot.SLOT_PRIMARY)
        Game():GetItemPool():RemoveCollectible(PURGATORY_FLAME)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnGabrielInit)
