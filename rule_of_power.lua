local mod = RegisterMod("MyMod", 1)
local RuleOfPower = Isaac.GetItemIdByName("Rule of Power")
local GoldenKey = Isaac.GetItemIdByName("Golden Key")
local MomsKey = Isaac.GetItemIdByName("Mom's Key")
local TheCompass = Isaac.GetItemIdByName("The Compass")

-- Callback function to handle room entry
local function OnRoomChange()
    local player = Isaac.GetPlayer(0)
    
    -- Check if the player has the Rule of Power item
    if player:HasCollectible(RuleOfPower) then
        local room = Game():GetRoom()
        local roomType = room:GetType()

        -- Check if the room is a Challenge Room or Boss Challenge Room
        if roomType == RoomType.ROOM_CHALLENGE or roomType == RoomType.ROOM_BOSSRUSH then
            -- Open the doors to the room
            for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
                local door = room:GetDoor(i)
                if door then
                    door:TryUnlock(player, true) -- Use the player and force unlock
                end
            end
        end
    end
end

-- Callback function to handle additional rewards
local function OnChallengeRoomClear()
    local player = Isaac.GetPlayer(0)
    
    -- Check if the player has the Rule of Power item
    if player:HasCollectible(RuleOfPower) then
        local room = Game():GetRoom()
        local roomType = room:GetType()

        -- Check if the room is a Challenge Room
        if roomType == RoomType.ROOM_CHALLENGE then
            -- Base 10% chance to spawn additional rewards
            local rewardChance = 0.1

            -- Synergy with Mom's Key: Increase reward chance
            if player:HasCollectible(MomsKey) then
                rewardChance = rewardChance + 0.1
            end

            -- Spawn additional rewards based on the calculated chance
            if math.random() < rewardChance then
                local position = room:FindFreePickupSpawnPosition(player.Position, 0, true)
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, position, Vector(0,0), nil)
            end
        end
    end
end

-- Callback function to handle synergies
local function EvaluateSynergies(player)
    -- Synergy with Golden Key: Open all locked doors and chests for free
    if player:HasCollectible(RuleOfPower) and player:HasCollectible(GoldenKey) then
        player:AddGoldenKey()
    end

    -- Synergy with The Compass: Reveal the map
    if player:HasCollectible(RuleOfPower) and player:HasCollectible(TheCompass) then
        player:UseCard(Card.CARD_WORLD, UseFlag.USE_NOANIM)
    end
end

-- Register the callbacks
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OnRoomChange)
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, OnChallengeRoomClear)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EvaluateSynergies)