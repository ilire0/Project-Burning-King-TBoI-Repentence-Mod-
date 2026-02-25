local mod = PBK

-- Player Type
local taintedGabrielType = Isaac.GetPlayerTypeByName("Gabriel", true)

-- Item
local holyOutburstID = Isaac.GetItemIdByName("Holy Outburst")

-- Optional Costume
local taintedHair = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_tainted_hair.anm2")

-------------------------------------------------
-- PLAYER INIT
-------------------------------------------------

function mod:OnTaintedGabrielInit(player)
    if player:GetPlayerType() ~= taintedGabrielType then return end

    -- Costume
    if taintedHair then
        player:AddNullCostume(taintedHair)
    end

    -- Pocket Active Item
    player:SetPocketActiveItem(holyOutburstID, ActiveSlot.SLOT_POCKET, true)

    -- Remove from item pool
    Game():GetItemPool():RemoveCollectible(holyOutburstID)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnTaintedGabrielInit)

-------------------------------------------------
-- HOLY OUTBURST USE
-------------------------------------------------

function mod:OnHolyOutburstUse(_, _, player)
    if player:GetPlayerType() ~= taintedGabrielType then return end

    -- Holy Creep Explosion
    local creep = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.PLAYER_CREEP_HOLYWATER,
        0,
        player.Position,
        Vector.Zero,
        player
    ):ToEffect()

    if creep then
        creep.Scale = 2
        creep:Update()
    end

    return true
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnHolyOutburstUse, holyOutburstID)
