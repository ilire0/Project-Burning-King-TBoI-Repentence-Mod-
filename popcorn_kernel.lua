local PopcornMod = RegisterMod("Popcorn Kernel", 1)
local PopcornItem = Isaac.GetItemIdByName("Popcorn Kernel")

-- Use Item: Fire a big, yellow-white bouncing "corn" tear
function PopcornMod:UsePopcorn(_, rng, player)
    -- Get real aiming direction, including diagonals
    local aimDir = player:GetAimDirection()
    local velocity = aimDir:Normalized() * 10

    -- If not shooting, use the last movement direction
    if aimDir:Length() == 0 then
        velocity = player:GetLastDirection():Normalized() * 10
    end

    -- Fire a big corn-style tear
    local tear = player:FireTear(player.Position, velocity, false, true, false):ToTear()
    if tear then
        tear:GetData().IsPopcornCorn = true

        local sprite = tear:GetSprite()
        if sprite then
            sprite.Scale = Vector(2.5, 2.5)
        end

        tear.Color = Color(1.2, 1.1, 0.6, 1, 0.1, 0.1, 0)
        tear.TearFlags = tear.TearFlags | TearFlags.TEAR_PULSE
        tear.Variant = TearVariant.SPORE

        -- Set big tear damage to 3x Isaac's current damage
        tear.CollisionDamage = player.Damage * 3
    end

    return true
end
PopcornMod:AddCallback(ModCallbacks.MC_USE_ITEM, PopcornMod.UsePopcorn, PopcornItem)

-- On tear update: split into smaller corn tears when it dies
function PopcornMod:OnTearUpdate(tear)
    if tear:GetData().IsPopcornCorn then
        if tear:IsDead() then
            local angleBase = tear.Velocity:GetAngleDegrees()

            for i = 1, 3 do
                local angle = angleBase + (i - 2) * 30
                local dir = Vector.FromAngle(angle) * 7

                local smallTear = Isaac.Spawn(
                    EntityType.ENTITY_TEAR,
                    TearVariant.SPORE,
                    0,
                    tear.Position,
                    dir,
                    nil
                ):ToTear()

                if smallTear then
                    local sprite = smallTear:GetSprite()
                    if sprite then
                        sprite.Scale = Vector(0.8, 0.8)
                    end

                    smallTear.Color = Color(1.1, 1.0, 0.5, 1, 0, 0, 0)
                    smallTear.TearFlags = smallTear.TearFlags | TearFlags.TEAR_WIGGLE

                    -- Small tear deals regular damage
                    local player = Isaac.GetPlayer(0)
                    smallTear.CollisionDamage = player.Damage
                end
            end

            -- Optional: 10% chance to spawn a coin
            if math.random() <= 0.1 then
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0, tear.Position, Vector(0, 0), nil)
            end
        end
    end
end
PopcornMod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, PopcornMod.OnTearUpdate)
