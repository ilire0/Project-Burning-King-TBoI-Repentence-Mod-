--- Loaded Die Effect
local mod = RegisterMod("MyMod", 1)
local game = Game()
local rng = RNG()
local sfx = SFXManager()

local LOADED_DIE_ITEM = Isaac.GetItemIdByName("Loaded Die")
local usedRooms = {}  -- Table to track rooms where the effect has been used

-- Function to roll the die with Luck influence
local function RollLoadedDie(luck)
    local roll = rng:RandomInt(6) + 1  -- Base roll (1-6)

    if luck <= -5 then
        -- Force roll to be between 1 and 4 for bad luck
        roll = rng:RandomInt(4) + 1
    end

    if luck >= 5 then
        -- Luck 5+: Reduce chance of rolling 1-2
        if roll <= 2 and rng:RandomFloat() < (luck / 15) then
            roll = roll + rng:RandomInt(4) + 1  -- Reroll to 3-6
        end
    end

    if luck >= 10 then
        -- Luck 10+: No negative rerolls (always 3+)
        roll = math.max(roll, 3)
    end

    return roll
end

-- Function to determine the item pool based on the room type
local function GetRoomItemPool()
    local level = game:GetLevel()
    local roomDesc = level:GetCurrentRoomDesc()
    local roomType = roomDesc.Data.Type

    if roomType == RoomType.ROOM_TREASURE then
        return ItemPoolType.POOL_TREASURE
    elseif roomType == RoomType.ROOM_CURSE then
        return ItemPoolType.POOL_CURSE
    elseif roomType == RoomType.ROOM_SHOP then
        return ItemPoolType.POOL_SHOP
    elseif roomType == RoomType.ROOM_DEVIL then
        return ItemPoolType.POOL_DEVIL
    elseif roomType == RoomType.ROOM_ANGEL then
        return ItemPoolType.POOL_ANGEL
    elseif roomType == RoomType.ROOM_SECRET then
        return ItemPoolType.POOL_SECRET
    elseif roomType == RoomType.ROOM_LIBRARY then
        return ItemPoolType.POOL_LIBRARY
    elseif roomType == RoomType.ROOM_BOSS then
        return ItemPoolType.POOL_BOSS
    elseif roomType == RoomType.ROOM_PLANETARIUM then
        return ItemPoolType.POOL_PLANETARIUM
    else
        return ItemPoolType.POOL_TREASURE  -- Default to treasure pool if no specific pool is found
    end
end

local function RerollWithDelay(pickup, newItem)
    local pos = pickup.Position
    game:SpawnParticles(pos, EffectVariant.POOF01, 1, 0, Color.Default, 0)  -- Smoke effect
    sfx:Play(SoundEffect.SOUND_FART, 1, 0, false, 1)  -- Play damage noise

    -- Wait for a few frames (3 frames delay)
    for i = 1, 7 do
        coroutine.yield()
    end

    -- Morph the item after the delay
    pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, true)
end

-- Function to handle item pickup
function mod:OnItemPickup(pickup)
    local player = Isaac.GetPlayer(0)  -- Assuming single player for simplicity
    if player:HasCollectible(LOADED_DIE_ITEM) and pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        local itemConfig = Isaac.GetItemConfig():GetCollectible(pickup.SubType)
        if itemConfig and itemConfig.Type == ItemType.ITEM_ACTIVE then
            return  -- Ignore active items
        end

        local level = game:GetLevel()
        local roomDesc = level:GetCurrentRoomDesc()
        local roomID = roomDesc.GridIndex

        if usedRooms[roomID] then
            return  -- Prevent multiple activations in the same room
        end

        local luck = player.Luck
        local roll = RollLoadedDie(luck)
        local itemPool = game:GetItemPool()

        -- Show visual effect for using Loaded Die
        player:AnimateCollectible(LOADED_DIE_ITEM, "UseItem", "PlayerPickup")

        if roll <= 2 then
            -- BAD roll: Change the item **on the pedestal** to something else
            local newItem = itemPool:GetCollectible(GetRoomItemPool(), false)
            mod:StartCoroutine(RerollWithDelay, pickup, newItem)
            
        elseif roll >= 5 then
            -- GOOD roll: Spawn an **extra item pedestal** with a random item
            local extraItem = itemPool:GetCollectible(GetRoomItemPool(), false)
            local spawnPos = pickup.Position + Vector(40, 0)  -- Slightly offset from original item
            local spawnedPickup = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, extraItem, spawnPos, Vector(0,0), nil)
            spawnedPickup:GetData().isSpawnedByLoadedDie = true  -- Mark the spawned item
            game:SpawnParticles(spawnPos, EffectVariant.POOF01, 1, 0, Color.Default, 0)  -- Smoke effect
        end

        usedRooms[roomID] = true  -- Mark the Loaded Die as used in this room
    end
end

-- Callback to handle when a collectible is initialized
function mod:OnPickupInit(pickup)
    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        pickup:GetData().isProcessed = false
    end
end

-- Callback to handle when a collectible is updated
function mod:OnPickupUpdate(pickup)
    if pickup.Variant == PickupVariant.PICKUP_COLLECTIBLE and not pickup:GetData().isProcessed then
        if pickup:IsShopItem() or pickup:GetData().isSpawnedByLoadedDie then
            return
        end
        mod:OnItemPickup(pickup)
        pickup:GetData().isProcessed = true
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.OnPickupInit, PickupVariant.PICKUP_COLLECTIBLE)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, mod.OnPickupUpdate, PickupVariant.PICKUP_COLLECTIBLE)

function mod:StartCoroutine(func, ...)
    local co = coroutine.create(func)
    local function step(...)
        local success, result = coroutine.resume(co, ...)
        if success and coroutine.status(co) ~= "dead" then
            mod:AddCallback(ModCallbacks.MC_POST_UPDATE, step)
        end
    end
    step(...)
end

