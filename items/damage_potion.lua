local mod = PBK
local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local damagePotionDamage = 20

function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(damagePotion)

        if itemCount > 0 then
            local baseDamage = player.Damage
            local totalBonus = damagePotionDamage * itemCount
            local finalDamage = (baseDamage + totalBonus) * 0.5

            player.Damage = finalDamage
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)
