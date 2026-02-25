local mod = RegisterMod("PBK", 1)

local FRAGMENT_OF_SOL = Isaac.GetTrinketIdByName("Fragment of Sol")

----------------------------------------------------
-- Add Burning Tear Chance
----------------------------------------------------
function mod:Sol_TearInit(tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
    if not player then return end
    if not player:HasTrinket(FRAGMENT_OF_SOL) then return end

    local mult = player:GetTrinketMultiplier(FRAGMENT_OF_SOL)

    local chance = math.min(10 + (player.Luck * 5), 50)
    chance = chance * mult

    local rng = player:GetTrinketRNG(FRAGMENT_OF_SOL)

    if rng:RandomFloat() <= (chance / 100) then
        tear:AddTearFlags(TearFlags.TEAR_BURN)
        tear.Color = Color(1, 0.8, 0.2, 1) -- golden tint
        tear:GetData().SolTear = true
    end
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.Sol_TearInit)

----------------------------------------------------
-- Sunburst On Hit
----------------------------------------------------
function mod:Sol_TearHit(tear, collider)
    if not tear:GetData().SolTear then return end

    if collider and collider:IsVulnerableEnemy() then
        local player = tear.SpawnerEntity:ToPlayer()
        if not player then return end

        local damage = player.Damage * 0.75
        local radius = 60

        Game():BombExplosionEffects(
            tear.Position,
            damage,
            TearFlags.TEAR_BURN,
            Color(1, 0.9, 0.3, 1),
            player,
            1,
            true,
            false
        )

        -- Small visual flare
        local effect = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.HALO,
            0,
            tear.Position,
            Vector.Zero,
            player
        )
    end
end

mod:AddCallback(ModCallbacks.MC_POST_TEAR_COLLISION, mod.Sol_TearHit)
