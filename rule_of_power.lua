-- Define the item IDs
local RuleOfPower = Isaac.GetItemIdByName("Rule of Power")
local GoldenKey = Isaac.GetItemIdByName("Golden Key")
local MomsKey = Isaac.GetItemIdByName("Mom's Key")
local TheCompass = Isaac.GetItemIdByName("The Compass")

-- Define a mod table
local myMod = RegisterMod("Rule of Power Mod", 1)

-- Function to unlock and open all doors
local function UnlockAndOpenAllDoors()
    local player = Isaac.GetPlayer(0)
    
    if player and player:HasCollectible(RuleOfPower) then
        local room = Game():GetRoom()

        for i = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
            local door = room:GetDoor(i)
            if door then
                door:TryUnlock(player, true)
                door:Open()
                print("Unlocked and opened door at slot: " .. tostring(i))
            else
                print("No door at slot: " .. tostring(i))
            end
        end
    else
        print("Player does not have Rule of Power")
    end
end

-- Callback function to handle additional rewards
local function OnChallengeRoomClear()
    local player = Isaac.GetPlayer(0)
    
    if player and player:HasCollectible(RuleOfPower) then
        local room = Game():GetRoom()
        local roomType = room:GetType()

        if roomType == RoomType.ROOM_CHALLENGE then
            local rewardChance = 0.1

            if player:HasCollectible(MomsKey) then
                rewardChance = rewardChance + 0.1
            end

            if math.random() < rewardChance then
                local position = room:FindFreePickupSpawnPosition(player.Position, 0, true)
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, 0, position, Vector(0,0), nil)
                print("Spawned additional reward")
            else
                print("No additional reward spawned")
            end
        end
    end
end

-- Callback function to handle synergies
local function EvaluateSynergies(_, player)
    if player and player:HasCollectible(RuleOfPower) then
        if player:HasCollectible(GoldenKey) then
            player:AddGoldenKey()
            print("Golden Key synergy activated")
        end

        if player:HasCollectible(TheCompass) then
            player:UseCard(Card.CARD_WORLD, UseFlag.USE_NOANIM)
            print("Compass synergy activated")
        end
    end
end

-- Register the callbacks
myMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, UnlockAndOpenAllDoors)
myMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, UnlockAndOpenAllDoors)
myMod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, OnChallengeRoomClear)
myMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, EvaluateSynergies)