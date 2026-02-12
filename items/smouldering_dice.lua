local mod = RegisterMod("MyMod", 1)

-- Smoldering Dice
local SMOLDERING_DICE = Isaac.GetItemIdByName("Smoldering Dice")
local rerolledItems = {} -- Table to track rerolled items for the current use


function mod:UseSmolderingDice(item, rng, player, useFlags, activeSlot, varData)
    local room = Game():GetRoom()
    local entities = Isaac.GetRoomEntities()
    local itemPool = Game():GetItemPool()
    local sfx = SFXManager()

    local wellDoneChance = 0.01
    local burnChance = 0.21
    local normalRerollChance = 0.60

    -- Raum → Pool bestimmen
    local roomType = room:GetType()
    local poolType = ItemPoolType.POOL_TREASURE

    if roomType == RoomType.ROOM_SHOP then
        poolType = ItemPoolType.POOL_SHOP
    elseif roomType == RoomType.ROOM_DEVIL then
        poolType = ItemPoolType.POOL_DEVIL
    elseif roomType == RoomType.ROOM_ANGEL then
        poolType = ItemPoolType.POOL_ANGEL
    elseif roomType == RoomType.ROOM_SECRET then
        poolType = ItemPoolType.POOL_SECRET
    elseif roomType == RoomType.ROOM_LIBRARY then
        poolType = ItemPoolType.POOL_LIBRARY
    elseif roomType == RoomType.ROOM_BOSS then
        poolType = ItemPoolType.POOL_BOSS
    elseif roomType == RoomType.ROOM_CURSE then
        poolType = ItemPoolType.POOL_CURSE
    elseif roomType == RoomType.ROOM_PLANETARIUM then
        poolType = ItemPoolType.POOL_PLANETARIUM
    end

    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP
            and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            local pickup = entity:ToPickup()

            if pickup and pickup.SubType > 0 then
                local config = Isaac.GetItemConfig():GetCollectible(pickup.SubType)
                if not config then goto continue end

                local quality = config.Quality
                local roll = rng:RandomFloat()

                local newItem = nil
                local maxAttempts = 50 -- !!! Wichtig gegen Endlosloops
                local attempts = 0

                -------------------------------------------------
                -- WELL DONE (Quality 4)
                -------------------------------------------------
                if roll < wellDoneChance then
                    repeat
                        newItem = itemPool:GetCollectible(poolType, true, rng:Next())
                        attempts = attempts + 1
                        local newConfig = Isaac.GetItemConfig():GetCollectible(newItem)
                    until (newConfig and newConfig.Quality == 4) or attempts >= maxAttempts

                    sfx:Play(SoundEffect.SOUND_HOLY, 1.0)

                    -------------------------------------------------
                    -- BURN (Quality 0)
                    -------------------------------------------------
                elseif roll < burnChance then
                    repeat
                        newItem = itemPool:GetCollectible(poolType, true, rng:Next())
                        attempts = attempts + 1
                        local newConfig = Isaac.GetItemConfig():GetCollectible(newItem)
                    until (newConfig and newConfig.Quality == 0) or attempts >= maxAttempts

                    sfx:Play(SoundEffect.SOUND_ISAAC_HURT_GRUNT, 1.0)

                    -------------------------------------------------
                    -- NORMAL REROLL
                    -------------------------------------------------
                elseif roll < normalRerollChance then
                    newItem = itemPool:GetCollectible(poolType, false, rng:Next())
                    sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 1.0)

                    -------------------------------------------------
                    -- +1 QUALITY
                    -------------------------------------------------
                else
                    local targetQuality = math.min(quality + 1, 4)

                    repeat
                        newItem = itemPool:GetCollectible(poolType, true, rng:Next())
                        attempts = attempts + 1
                        local newConfig = Isaac.GetItemConfig():GetCollectible(newItem)
                    until (newConfig and newConfig.Quality == targetQuality) or attempts >= maxAttempts

                    sfx:Play(SoundEffect.SOUND_POWERUP1, 1.0)
                end

                -------------------------------------------------
                -- Fallback wenn nichts gefunden wurde
                -------------------------------------------------
                if not newItem or not Isaac.GetItemConfig():GetCollectible(newItem) then
                    newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, false, rng:Next())
                end

                -------------------------------------------------
                -- Morph
                -------------------------------------------------
                if newItem then
                    pickup:Morph(
                        EntityType.ENTITY_PICKUP,
                        PickupVariant.PICKUP_COLLECTIBLE,
                        newItem,
                        true,
                        false,
                        false
                    )

                    Isaac.Spawn(
                        EntityType.ENTITY_EFFECT,
                        EffectVariant.POOF01,
                        0,
                        pickup.Position,
                        Vector.Zero,
                        nil
                    )
                end
            end
            ::continue::
        end
    end

    return true
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseSmolderingDice, SMOLDERING_DICE)
