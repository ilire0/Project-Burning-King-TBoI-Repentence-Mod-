-- Define the mod
local mod = RegisterMod("MyMod", 1)

-- Define the item ID for Duality Mirror
local DualityMirror = Isaac.GetItemIdByName("Duality Mirror")

-- Function to handle stat changes
function mod:onEvaluateCache(player, cacheFlag)
    if player:HasCollectible(DualityMirror) then
        -- Check for each stat and apply the doubling effect
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            local baseDamage = player:GetBaseDamage()
            local itemDamageBonus = player.Damage - baseDamage
            player.Damage = baseDamage + (itemDamageBonus * 2)
        end

        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            local baseTears = player:GetMaxTears()
            local itemTearsBonus = baseTears - player.MaxFireDelay
            player.MaxFireDelay = baseTears - (itemTearsBonus * 2)
        end

        if cacheFlag == CacheFlag.CACHE_SPEED then
            local baseSpeed = player:GetBaseMoveSpeed()
            local itemSpeedBonus = player.MoveSpeed - baseSpeed
            player.MoveSpeed = baseSpeed + (itemSpeedBonus * 2)
        end

        if cacheFlag == CacheFlag.CACHE_RANGE then
            local baseRange = player:GetBaseTearRange()
            local itemRangeBonus = player.TearRange - baseRange
            player.TearRange = baseRange + (itemRangeBonus * 2)
        end

        if cacheFlag == CacheFlag.CACHE_LUCK then
            local baseLuck = player:GetBaseLuck()
            local itemLuckBonus = player.Luck - baseLuck
            player.Luck = baseLuck + (itemLuckBonus * 2)
        end
    end
end

-- Register the cache evaluation callback
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.onEvaluateCache)

-- Add item to the game
function mod:Init()
    Isaac.DebugString("Duality Mirror Mod Loaded")
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.Init)