local mod = RegisterMod("MyMod", 1)

-- Smoldering Dice
local SMOLDERING_DICE = Isaac.GetItemIdByName("Smoldering Dice")
local rerolledItems = {}  -- Table to track rerolled items for the current use


function mod:UseSmolderingDice(item, rng, player, useFlags, activeSlot, varData)

    local room = Game():GetRoom()
    local entities = Isaac.GetRoomEntities()
    local itemPool = Game():GetItemPool()
    local sfx = SFXManager()

    local carBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
    local wellDoneChance = 0.01
    local burnChance = 0.21  -- 0.01 (well done) + 0.20 (burn)
    local normalRerollChance = 0.60  -- 0.01 + 0.20 + 0.39

    -- Determine the item pool based on the room type
    local roomType = room:GetType()
    local poolType = ItemPoolType.POOL_TREASURE  -- Default to treasure pool

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
        if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
            local smolderPickup = entity:ToPickup()
            if smolderPickup and smolderPickup.SubType ~= 0 then  -- Check if smolderPickup is not nil and not an empty pedestal
                local pickupId = smolderPickup.InitSeed
                -- Check if the item has already been rerolled in this use
                if rerolledItems[pickupId] then
                    goto continue
                end

                local itemConfig = Isaac.GetItemConfig():GetCollectible(smolderPickup.SubType)
                local quality = itemConfig and itemConfig.Quality or 0

                local roll = rng:RandomFloat()

                local newItem = nil
                local soundEffect = nil

                if roll < wellDoneChance then
                    -- Well Done: Reroll into a quality 4 item
                    newItem = itemPool:GetCollectible(poolType, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    while newItem and Isaac.GetItemConfig():GetCollectible(newItem).Quality < 4 do
                        newItem = itemPool:GetCollectible(poolType, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    if not newItem then
                        -- Fallback to any item
                        newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    soundEffect = SoundEffect.SOUND_HOLY  -- Positive sound effect
                elseif roll < burnChance then
                    -- Burn: Reroll into a quality 0 item
                    newItem = itemPool:GetCollectible(poolType, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    while newItem and Isaac.GetItemConfig():GetCollectible(newItem).Quality > 0 do
                        newItem = itemPool:GetCollectible(poolType, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    if not newItem then
                        -- Fallback to any item
                        newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    soundEffect = SoundEffect.SOUND_ISAAC_HURT_GRUNT  -- Negative sound effect
                elseif roll < normalRerollChance then
                    -- Normal Reroll (similar to D6)
                    newItem = itemPool:GetCollectible(poolType, false, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    if not newItem then
                        -- Fallback to any item
                        newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, false, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    soundEffect = SoundEffect.SOUND_NULL -- Neutral sound effect
                else
                    -- Reroll with +1 quality
                    local targetQuality = math.min(quality + 1, 4)
                    newItem = itemPool:GetCollectible(poolType, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    while newItem and Isaac.GetItemConfig():GetCollectible(newItem).Quality ~= targetQuality do
                        newItem = itemPool:GetCollectible(poolType, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    if not newItem then
                        -- Fallback to any item
                        newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, smolderPickup.InitSeed, CollectibleType.COLLECTIBLE_NULL)
                    end
                    soundEffect = SoundEffect.SOUND_POWERUP1  -- Positive sound effect
                end

                if newItem and Isaac.GetItemConfig():GetCollectible(newItem) then
                    smolderPickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, true, false, false)
                    sfx:Play(soundEffect, 1.0, 0, false, 1.0)
                    -- Create smoke effect (POOF01) at the pedestal
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, smolderPickup.Position, Vector(0,0), nil)
                    -- Mark the item as rerolled for this use
                    rerolledItems[pickupId] = true
                end
            end
            ::continue::
        end
    end

    -- Clear the rerolled items table after processing
    rerolledItems = {}

    return true
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UseSmolderingDice, SMOLDERING_DICE)