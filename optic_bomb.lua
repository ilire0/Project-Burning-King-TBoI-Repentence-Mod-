local mod = RegisterMod("MyMod", 1)

-- Optic Bomb Effect
local opticBomb = Isaac.GetItemIdByName("Optic Bomb")

function mod:onUpdate(player)
    if player:HasCollectible(opticBomb) then
        player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_PYROMANIAC)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.onUpdate)

function mod:onEnemyHit(entity, amount, flags, source, countdown)
    local player = source.Entity and source.Entity:ToPlayer()
    if player and player:HasCollectible(opticBomb) then
        entity:AddBurn(EntityRef(entity), 30, player.Damage * 0.1)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEnemyHit)

function mod:onEnemyDeath(entity)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(opticBomb) then
        local damage = player.Damage * 20
        local radius = math.min(100 + (player.Damage * 10), 300)
        -- Use BombExplosionEffects with correct parameters
        Game():BombExplosionEffects(entity.Position, damage, TearFlags.TEAR_NORMAL, Color(1, 0.5, 0, 1), player, 1, true, false)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.onEnemyDeath)