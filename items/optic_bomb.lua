local mod = PBK
local opticBomb = Isaac.GetItemIdByName("Optic Bomb")

local hasGivenPyromaniac = {}
local lastExplosionTime = 0
local cooldownDuration = 60 -- 60 frames = 1 second

-- Give Pyromaniac effect
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

-- Apply burn properly when tear hits enemy
function mod:onEnemyHit(entity, amount, flags, source, countdown)
    -- Only apply to vulnerable enemies
    if not entity:IsVulnerableEnemy() then return end

    -- Make sure the damage source exists and is a tear
    local tear = source.Entity
    if tear and tear.Type == EntityType.ENTITY_TEAR then
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        if player and player:HasCollectible(opticBomb) then
            -- Burn lasts 60 frames (~1 sec), 15% of player damage per tick
            entity:AddBurn(EntityRef(player), 90, player.Damage * 0.2)
        end
    end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEnemyHit)

-- Explosion on enemy death
function mod:onEnemyDeath(entity)
    if not entity:IsVulnerableEnemy() or entity:IsBoss() then return end

    local player = Isaac.GetPlayer(0)
    if not player:HasCollectible(opticBomb) then return end

    local game = Game()
    local frameCount = game:GetFrameCount()
    if frameCount - lastExplosionTime < cooldownDuration then return end

    -- Scale explosion: base + player damage, max radius 150
    local damage = math.min(player.Damage * 5, 50) -- cap damage for balance
    local radius = math.min(50 + player.Damage * 2, 150)

    -- Explosion effect
    game:BombExplosionEffects(entity.Position, damage, TearFlags.TEAR_NORMAL, Color(0.2, 0.2, 0.2, 1), player, 1, true,
        false)
    lastExplosionTime = frameCount
end

mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.onEnemyDeath)
