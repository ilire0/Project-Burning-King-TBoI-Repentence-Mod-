local mod = RegisterMod("MyMod", 1)
local DUALITY_MIRROR = Isaac.GetItemIdByName("Duality Mirror")

local initialStats = {}

function mod:OnPlayerInit(player)
    -- Store initial stats
    initialStats[player.InitSeed] = {
        Damage = player.Damage,
        Speed = player.MoveSpeed,
        Range = player.TearRange,
        FireDelay = player.MaxFireDelay,
        Luck = player.Luck
    }
end

function mod:EvaluateDualityMirrorCache(player, cacheFlag)
    if player:HasCollectible(DUALITY_MIRROR) then
        local stats = initialStats[player.InitSeed]
        if not stats then return end

        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            local additionalDamage = player.Damage - stats.Damage
            player.Damage = stats.Damage + additionalDamage * 2
        end
        if cacheFlag == CacheFlag.CACHE_SPEED then
            local additionalSpeed = player.MoveSpeed - stats.Speed
            player.MoveSpeed = stats.Speed + additionalSpeed * 2
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            local additionalRange = player.TearRange - stats.Range
            player.TearRange = stats.Range + additionalRange * 2
        end
        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            local additionalFireDelay = player.MaxFireDelay - stats.FireDelay
            player.MaxFireDelay = stats.FireDelay + additionalFireDelay * 0.5
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            local additionalLuck = player.Luck - stats.Luck
            player.Luck = stats.Luck + additionalLuck * 2
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnPlayerInit)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateDualityMirrorCache)