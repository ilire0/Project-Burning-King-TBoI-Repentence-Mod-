local mod = PBK
local DUALITY_MIRROR = Isaac.GetItemIdByName("Duality Mirror")

local initialStats = {}

function mod:OnPlayerInit(player)
    -- Store initial stats only if they haven't been stored before
    if not initialStats[player.InitSeed] then
        initialStats[player.InitSeed] = {
            Damage = player.Damage,
            Speed = player.MoveSpeed,
            Range = player.TearRange,
            FireDelay = player.MaxFireDelay,
            Luck = player.Luck
        }
    end
end

function mod:EvaluateDualityMirrorCache(player, cacheFlag)
    if player:HasCollectible(DUALITY_MIRROR) then
        local stats = initialStats[player.InitSeed]
        if not stats then return end -- Prevent errors if stats are missing

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
            local additionalFireDelay = player.MaxFireDelay - stats.FireDelay            -- FireDelay works inversely
            player.MaxFireDelay = math.max(1, stats.FireDelay + additionalFireDelay * 2) -- Ensure FireDelay stays positive
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            local additionalLuck = player.Luck - stats.Luck
            player.Luck = stats.Luck + additionalLuck * 2
        end
    end
end

-- Handle player transformations (e.g. Polymorph)
function mod:OnPlayerUpdate(player)
    local currentSeed = player.InitSeed
    if not initialStats[currentSeed] then
        mod:OnPlayerInit(player) -- Reinitialize stats if needed
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnPlayerInit)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateDualityMirrorCache)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OnPlayerUpdate)
