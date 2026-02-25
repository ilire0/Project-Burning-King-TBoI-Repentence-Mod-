local Mod = PBK
-- Waxen Wings Trinket
local WaxenWings = {}
WaxenWings.TrinketID = Isaac.GetTrinketIdByName("Waxen Wings")

function WaxenWings:Evaluate(player)
    if player:HasTrinket(WaxenWings.TrinketID) then
        player.CanFly = true
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end
end

-- Double damage
Mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
    if entity:ToPlayer() and entity:ToPlayer():HasTrinket(WaxenWings.TrinketID) then
        amount = amount * 2
        -- 10% chance to destroy trinket on damage
        if math.random() < 0.1 then
            entity:TryRemoveTrinket(WaxenWings.TrinketID)
        end
    end
    return amount
end)

Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if flag == CacheFlag.CACHE_DAMAGE then
        WaxenWings:Evaluate(player)
    end
end)
