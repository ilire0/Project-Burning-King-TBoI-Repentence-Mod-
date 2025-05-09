CricketsHowlMod = RegisterMod("Bewitching Howl", 1)

local CricketsHowl = {
    ItemId = Isaac.GetItemIdByName("Bewitching Howl"),
    CharmDuration = 3 * 30, -- 3 seconds in game ticks
    BossStunDuration = 1.5 * 30, -- 1.5 seconds in game ticks
    FlyCountMin = 1,
    FlyCountMax = 3
}

function CricketsHowl:UseItem(_, _, player)
    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        if entity:IsVulnerableEnemy() then
            if entity:IsBoss() then
                entity:AddFreeze(EntityRef(player), CricketsHowl.BossStunDuration)
            else
                entity:AddCharmed(EntityRef(player), CricketsHowl.CharmDuration)
            end
        end
    end

    -- Spawn blue flies
    local flyCount = math.random(CricketsHowl.FlyCountMin, CricketsHowl.FlyCountMax)
    for i = 1, flyCount do
        player:AddBlueFlies(1, player.Position, player)
    end

    -- Spawn a blue spider
    player:AddBlueSpider(player.Position)
end

CricketsHowlMod:AddCallback(ModCallbacks.MC_USE_ITEM, CricketsHowl.UseItem, CricketsHowl.ItemId)