local mod = RegisterMod("MyMod", 1)
local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local damagePotionDamage = 10

-- Store whether the player has picked up "Damage Potion" in this run
local halvedDamageUp = false

function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        -- Check if the player has picked up the "Damage Potion"
        local itemCount = player:GetCollectibleNum(damagePotion)
        
        -- If the player has picked up the Damage Potion, apply its effect
        if itemCount > 0 then
            if not halvedDamageUp then
                -- Add the 10 damage from the "Damage Potion"
                player.Damage = player.Damage + damagePotionDamage
                
                -- Set the flag to halved future damage up effects
                halvedDamageUp = true
            end
        end
        
        -- If the Damage Potion was picked up, halve future damage up items
        if halvedDamageUp then
            -- Check if a damage up item is present and halve its effect
            if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
                player.Damage = player.Damage * 0.5
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)
