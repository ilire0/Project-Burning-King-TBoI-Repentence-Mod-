-- Define the item ID for the new passive item
local AllfatherWorm = Isaac.GetItemIdByName("Allfather Worm")

-- Define a mod table
local myMod = RegisterMod("Allfather Worm Mod", 1)

-- List of Worm trinket IDs
local wormTrinkets = {
    TrinketType.TRINKET_WIGGLE_WORM,
    TrinketType.TRINKET_RING_WORM,
    TrinketType.TRINKET_FLAT_WORM,
    TrinketType.TRINKET_PULSE_WORM,
    TrinketType.TRINKET_HOOK_WORM,
    TrinketType.TRINKET_TAPE_WORM,
    TrinketType.TRINKET_LAZY_WORM,
    TrinketType.TRINKET_OUROBOROS_WORM,
    TrinketType.TRINKET_WHIP_WORM,
    TrinketType.TRINKET_BRAIN_WORM

}

-- Variables to track the current trinket and timer
local currentWormIndex = 1
local effectDuration = 300 -- Duration for each effect in frames (5 seconds at 60 FPS)
local effectTimer = 0

-- Function to apply the current Worm trinket effect
local function ApplyWormTrinket(player)
    -- Remove any existing Worm trinket
    for _, trinket in ipairs(wormTrinkets) do
        if player:HasTrinket(trinket) then
            player:TryRemoveTrinket(trinket)
        end
    end

    -- Give the player the current Worm trinket
    player:AddTrinket(wormTrinkets[currentWormIndex])
    player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false) -- Simulate gulping the trinket
end

-- Function to handle the update logic
local function OnGameUpdate()
    local player = Isaac.GetPlayer(0)

    if player:HasCollectible(AllfatherWorm) then
        effectTimer = effectTimer + 1

        if effectTimer >= effectDuration then
            -- Remove the current Worm trinket
            player:TryRemoveTrinket(wormTrinkets[currentWormIndex])

            -- Move to the next Worm trinket
            currentWormIndex = currentWormIndex % #wormTrinkets + 1
            ApplyWormTrinket(player)
            effectTimer = 0
        end
    end
end

-- Function to replace Worm trinkets with random trinkets
local function OnPickupInit(pickup)
    if pickup.Variant == PickupVariant.PICKUP_TRINKET then
        local trinketType = pickup.SubType
        for _, wormTrinket in ipairs(wormTrinkets) do
            if trinketType == wormTrinket then
                -- Replace with a random trinket
                local newTrinket = Game():GetItemPool():GetTrinket()
                pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, newTrinket, true, false, false)
                break
            end
        end
    end
end

-- Register the callbacks
myMod:AddCallback(ModCallbacks.MC_POST_UPDATE, OnGameUpdate)
myMod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, OnPickupInit)