local mod = RegisterMod("MyMod", 1)

--- Bee Buster
local BEE_BUSTER = Isaac.GetItemIdByName("Bee Buster")

local BEE_BUSTER_STATS = {
    Damage = 0.25
}

function mod:UseBeeBuster(item, rng, player, useFlags, activeSlot, varData)
    local room = Game():GetRoom()
    local fireCount = 0

    local entities = Isaac.GetRoomEntities()
    local sfx = SFXManager()

    -- Count all flames before removing them
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_FIREPLACE or 
           (entity.Type == EntityType.ENTITY_EFFECT and 
            (entity.Variant == EffectVariant.RED_CANDLE_FLAME or 
             entity.Variant == EffectVariant.BLUE_FLAME)) then
            fireCount = fireCount + 1
        end
    end

    -- Remove all flames, spawn smoke effects, and play extinguish sound
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_FIREPLACE or 
           (entity.Type == EntityType.ENTITY_EFFECT and 
            (entity.Variant == EffectVariant.RED_CANDLE_FLAME or 
             entity.Variant == EffectVariant.BLUE_FLAME)) then
            -- Spawn smoke effect at the flame's position
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector(0, 0), nil)
            -- Play extinguish sound
            sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1.0, 0, false, 1.0)
            entity:Remove()
        end
    end

    if fireCount > 0 then
        local data = player:GetData()
        data.BeeBusterFlamesPurged = (data.BeeBusterFlamesPurged or 0) + fireCount

        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()

        -- Full black heart for every 10th flame
        local previousFlames = data.BeeBusterFlamesPurged - fireCount
        local newFlames = data.BeeBusterFlamesPurged

        for i = previousFlames + 1, newFlames do
            if i % 10 == 0 then
                player:AddBlackHearts(2) -- Add a full black heart (2 half hearts)
            end
        end
    end

    return true
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseBeeBuster, BEE_BUSTER)

-- Renamed Stat-Boost Calculation
function mod:EvaluateBeeBusterCache(player, cacheFlag)
    local data = player:GetData()
    if data.BeeBusterFlamesPurged then
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + (BEE_BUSTER_STATS.Damage * data.BeeBusterFlamesPurged)
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateBeeBusterCache)