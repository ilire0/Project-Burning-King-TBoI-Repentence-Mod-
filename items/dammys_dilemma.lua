-- Define the item ID
local SafeDamocles = Isaac.GetItemIdByName("Dammy's Dilemma")

-- Define a mod table
local myMod = RegisterMod("Safe Damocles Mod", 1)

-- Variables to track the timer, processed rooms, and trapdoor
local teleportTimer = -1
local minTime = 60  -- Minimum time before teleportation (1 minute in frames)
local maxTime = 600 -- Maximum time before teleportation (5 minutes in frames)
local processedRooms = {}
local trapdoorPending = false

-- Function to start the timer
local function StartTeleportTimer()
    teleportTimer = math.random(minTime, maxTime)
end

-- Function to handle item duplication
local function TryDuplicateItem()
    local room = Game():GetRoom()
    local roomDesc = Game():GetLevel():GetCurrentRoomDesc()
    local roomID = roomDesc.SafeGridIndex

    -- Check if the room has already been processed
    if not processedRooms[roomID] then
        local hasPedestal = false

        -- Check for existing item pedestals
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                hasPedestal = true
                break
            end
        end

        -- Attempt duplication if a pedestal exists
        if hasPedestal and math.random() < 0.5 then
            local itemPool = Game():GetItemPool()
            local position = room:FindFreePickupSpawnPosition(Vector(320, 280), 0, true)
            local newItem = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, true, room:GetSpawnSeed())
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, position, Vector(0,0), nil)

            -- Play the item holding animation
            local player = Isaac.GetPlayer(0)
            player:AnimateCollectible(SafeDamocles)
        end

        -- Mark the room as processed
        processedRooms[roomID] = true
    end
end

-- Function to handle the effect of the item
local function OnPlayerDamage(_, entity, damageAmount, damageFlag, damageSource)
    local player = entity:ToPlayer()
    if player then
        local room = Game():GetRoom()
        local roomType = room:GetType()

        -- Ignore damage from Curse Room doors and Sacrifice Room spikes
        if not (damageFlag & DamageFlag.DAMAGE_CURSED_DOOR ~= 0 or 
                (damageFlag & DamageFlag.DAMAGE_SPIKES ~= 0 and roomType == RoomType.ROOM_SACRIFICE)) then
            if player:HasCollectible(SafeDamocles) and teleportTimer == -1 then
                StartTeleportTimer()
            end
        end
    end
end

-- Function to update the timer each frame
local function OnGameUpdate()
    if teleportTimer > 0 then
        teleportTimer = teleportTimer - 1
        if teleportTimer == 0 then
            -- Set the flag to spawn the trapdoor in the next room
            trapdoorPending = true
        end
    end
end

-- Function to handle room entry
local function OnNewRoom()
    local player = Isaac.GetPlayer(0)
    local room = Game():GetRoom()

    if player:HasCollectible(SafeDamocles) then
        TryDuplicateItem()
    end

    -- If the trapdoor is pending, spawn it and lock the doors
    if trapdoorPending then
        -- Give the player a Hangman card
        player:AddCard(Card.CARD_HANGED_MAN)

        -- Spawn a trapdoor in front of each door
        for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
            local door = room:GetDoor(i)
            if door then
                local doorPosition = door.Position
                room:SpawnGridEntity(room:GetGridIndex(doorPosition), GridEntityType.GRID_TRAPDOOR, 0, 0, 0)
                door:Close()
                door:Bar()
            end
        end

        -- Reset the trapdoor pending flag
        trapdoorPending = false
    end
end

-- Function to reset the effect on a new floor
local function OnNewLevel()
    teleportTimer = -1
    processedRooms = {}  -- Clear processed rooms for the new floor
    trapdoorPending = false
end

-- Register the callbacks
myMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, OnPlayerDamage, EntityType.ENTITY_PLAYER)
myMod:AddCallback(ModCallbacks.MC_POST_UPDATE, OnGameUpdate)
myMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, OnNewLevel)
myMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OnNewRoom)