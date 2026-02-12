local mod = RegisterMod("PBK", 1)

-- Bell Pepper Setup
local BELL_PEPPER = Isaac.GetItemIdByName("Bell Pepper")
local FIRE_DURATION_FRAMES = 900
local FIRE_BLOCK_LIMIT = 4
local FIRE_SPEED = 8

local bellPepperFires = {} -- Track spawned fire effects

-- Spawn Green Fire in Shooting Direction
function mod:BellPepper_FireTear(tear)
    local player = tear.Parent:ToPlayer()
    if not player or not player:HasCollectible(BELL_PEPPER) then return end

    local luck = player.Luck
    local chance = math.min(10 + math.floor(luck * 4), 50)

    if math.random(100) <= chance then
        local shootDir = player:GetFireDirection()
        local dirVector = Vector.Zero

        if shootDir == Direction.LEFT then
            dirVector = Vector(-1, 0)
        elseif shootDir == Direction.UP then
            dirVector = Vector(0, -1)
        elseif shootDir == Direction.RIGHT then
            dirVector = Vector(1, 0)
        elseif shootDir == Direction.DOWN then
            dirVector = Vector(0, 1)
        end

        if dirVector:Length() > 0 then
            local fire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RED_CANDLE_FLAME, 0, player.Position,
                dirVector * FIRE_SPEED, player):ToEffect()

            if fire and fire:GetSprite() then
                fire:GetSprite():Play("Appear", true)
                fire.Color = Color(0, 1, 0, 1)
                fire:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK | EntityFlag.FLAG_NO_TARGET)

                bellPepperFires[fire.InitSeed] = {
                    Entity = fire,
                    Timer = 0,
                    Blocked = 0
                }
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.BellPepper_FireTear)

-- Update Fire Timers and Handle Wall Collision
function mod:BellPepper_UpdateFires()
    for seed, data in pairs(bellPepperFires) do
        if data.Entity and data.Entity:Exists() then
            local fire = data.Entity
            data.Timer = data.Timer + 1

            -- Wall collision detection
            if Game():GetRoom():GetGridCollisionAtPos(fire.Position) ~= GridCollisionClass.COLLISION_NONE then
                fire.Velocity = Vector.Zero
                fire:Remove()
                bellPepperFires[seed] = nil
            elseif data.Timer >= FIRE_DURATION_FRAMES then
                fire:Remove()
                bellPepperFires[seed] = nil
            end
        else
            bellPepperFires[seed] = nil
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.BellPepper_UpdateFires)

-- Handle Projectile Blocking
function mod:BellPepper_BlockProjectiles(entity, damageAmount, damageFlags, source)
    if entity.Type == EntityType.ENTITY_EFFECT and entity.Variant == EffectVariant.RED_CANDLE_FLAME then
        local data = bellPepperFires[entity.InitSeed]
        if data and source and source.Type == EntityType.ENTITY_PROJECTILE then
            data.Blocked = data.Blocked + 1
            if data.Blocked >= FIRE_BLOCK_LIMIT then
                entity:Remove()
                bellPepperFires[entity.InitSeed] = nil
            end
            return false
        end
    end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.BellPepper_BlockProjectiles)

-- Clean up on New Room
function mod:BellPepper_NewRoom()
    bellPepperFires = {}
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.BellPepper_NewRoom)
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.BellPepper_AddToPool)
