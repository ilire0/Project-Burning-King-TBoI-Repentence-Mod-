local mod = RegisterMod("MyMod", 1)

-- Define the item ID for the new Battery Item
local BATTERY_ITEM = Isaac.GetItemIdByName("Battery Booster")

-- Function to increase battery spawn chance
function mod:IncreaseBatterySpawnChance()
    local level = Game():GetLevel()
    local roomDesc = level:GetCurrentRoomDesc()
    local roomType = roomDesc.Data.Type

    -- Increase battery spawn chance in applicable rooms
    if roomType == RoomType.ROOM_TREASURE or roomType == RoomType.ROOM_SHOP then
        local rng = RNG()
        rng:SetSeed(Random(), 1)
        if rng:RandomFloat() < 0.2 then  -- 20% chance to spawn a battery
            local pos = Game():GetRoom():FindFreePickupSpawnPosition(Vector(320, 280), 0, true)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, BatterySubType.BATTERY_NORMAL, pos, Vector(0, 0), nil)
        end
    end
end

-- Callback for when a pickup is initialized
function mod:OnPickupInit(pickup)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(BATTERY_ITEM) and pickup.Variant == PickupVariant.PICKUP_LIL_BATTERY then
        if not pickup:GetData().Processed then
            if pickup.SubType == BatterySubType.BATTERY_MICRO then
                -- Transform small battery into normal battery
                pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_LIL_BATTERY, BatterySubType.BATTERY_NORMAL, true)
            end
            -- Mark the battery as processed
            pickup:GetData().Processed = true
        end
    end
end

-- Callback for new room to apply effects
function mod:OnNewRoom()
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(BATTERY_ITEM) then
        mod:IncreaseBatterySpawnChance()
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.OnPickupInit, PickupVariant.PICKUP_LIL_BATTERY)