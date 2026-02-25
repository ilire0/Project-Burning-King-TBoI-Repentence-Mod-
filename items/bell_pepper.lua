local mod = RegisterMod("PBK", 1)

local BELL_PEPPER = Isaac.GetItemIdByName("Bell Pepper")

local FIRE_DURATION_FRAMES = 900
local FIRE_BLOCK_LIMIT = 4
local FIRE_SPEED = 10

local bellPepperFires = {}

----------------------------------------------------
-- Spawn Green Flame When Shooting
----------------------------------------------------
function mod:BellPepper_FireTear(tear)
    local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
    if not player then return end
    if not player:HasCollectible(BELL_PEPPER) then return end

    local chance = math.min(10 + (player.Luck * 4), 50)

    if player:GetCollectibleRNG(BELL_PEPPER):RandomFloat() <= (chance / 100) then
        local dir = tear.Velocity:Normalized()
        if dir:Length() == 0 then return end

        local fire = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.RED_CANDLE_FLAME,
            0,
            player.Position,
            dir * FIRE_SPEED,
            player
        ):ToEffect()

        if fire then
            fire:GetSprite():Play("Appear", true)
            fire.Color = Color(0.2, 1, 0.2, 1) -- nice green
            fire:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
            fire:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)


            bellPepperFires[fire.InitSeed] = {
                Entity = fire,
                Timer = 0,
                Blocked = 0
            }
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.BellPepper_FireTear)

----------------------------------------------------
-- Update Flames
----------------------------------------------------
function mod:BellPepper_UpdateFires()
    for seed, data in pairs(bellPepperFires) do
        if not data.Entity or not data.Entity:Exists() then
            bellPepperFires[seed] = nil
        else
            local fire = data.Entity
            data.Timer = data.Timer + 1

            -- Lifetime check
            if data.Timer >= FIRE_DURATION_FRAMES then
                fire:Remove()
                bellPepperFires[seed] = nil
            end

            -- Wall collision
            if Game():GetRoom():GetGridCollisionAtPos(fire.Position) ~= GridCollisionClass.COLLISION_NONE then
                fire:Remove()
                bellPepperFires[seed] = nil
            end

            -- Projectile blocking
            for _, projectile in ipairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE)) do
                if projectile.Position:Distance(fire.Position) < 25 then
                    projectile:Remove()

                    data.Blocked = data.Blocked + 1

                    if data.Blocked >= FIRE_BLOCK_LIMIT then
                        fire:Remove()
                        bellPepperFires[seed] = nil
                        break
                    end
                end
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.BellPepper_UpdateFires)

----------------------------------------------------
-- Clean on New Room
----------------------------------------------------
function mod:BellPepper_NewRoom()
    for _, data in pairs(bellPepperFires) do
        if data.Entity and data.Entity:Exists() then
            data.Entity:Remove()
        end
    end
    bellPepperFires = {}
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.BellPepper_NewRoom)
