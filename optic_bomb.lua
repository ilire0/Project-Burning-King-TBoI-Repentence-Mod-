local mod = RegisterMod("MyMod", 1)
local opticBomb = Isaac.GetItemIdByName("Optic Bomb")

local hasGivenPyromaniac = {}
local lastExplosionTime = 0
local cooldownDuration = 15

function mod:onUpdate(player)
    local id = player:GetCollectibleRNG(opticBomb):GetSeed()
    if player:HasCollectible(opticBomb) and not hasGivenPyromaniac[id] then
        player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_PYROMANIAC, false)
        hasGivenPyromaniac[id] = true
    elseif not player:HasCollectible(opticBomb) and hasGivenPyromaniac[id] then
        hasGivenPyromaniac[id] = nil
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.onUpdate)

function mod:onEnemyHit(entity, amount, flags, source, countdown)
    local player = source.Entity and source.Entity:ToPlayer()
    if player and player:HasCollectible(opticBomb) and entity:IsVulnerableEnemy() then
        entity:AddBurn(EntityRef(player), 30, player.Damage * 0.05)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEnemyHit)

function mod:onEnemyDeath(entity)
    local player = Isaac.GetPlayer(0)
    local game = Game()
    local frameCount = game:GetFrameCount()

    if player:HasCollectible(opticBomb) 
        and entity:IsVulnerableEnemy() 
        and not entity:IsBoss() 
        and (frameCount - lastExplosionTime >= cooldownDuration) then
        
        local damage = player.Damage * 10
        local radius = math.min(80 + (player.Damage * 5), 200)

        game:BombExplosionEffects(entity.Position, damage, TearFlags.TEAR_NORMAL, Color(1, 0.5, 0.2, 1), player, 1, true, false)
        lastExplosionTime = frameCount
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.onEnemyDeath)
