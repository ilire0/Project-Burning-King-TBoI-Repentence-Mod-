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
    TrinketType.TRINKET_OUROBOROS_WORM
}

-- Define stat boosts for each Worm trinket
local wormStatBoosts = {
    [TrinketType.TRINKET_WIGGLE_WORM] = { Damage = 0.5 },
    [TrinketType.TRINKET_RING_WORM] = { Tears = 0.5 },
    [TrinketType.TRINKET_FLAT_WORM] = { Range = 1.0 },
    [TrinketType.TRINKET_PULSE_WORM] = { ShotSpeed = 0.2 },
    [TrinketType.TRINKET_HOOK_WORM] = { TearHeight = -1.0 },
    [TrinketType.TRINKET_TAPE_WORM] = { Range = 1.5 },
    [TrinketType.TRINKET_LAZY_WORM] = { TearDelay = -1 },
    [TrinketType.TRINKET_OUROBOROS_WORM] = { Damage = 1.0 }
}

-- Variables to track the current trinket and timer
local currentWormIndex = 1
local effectDuration = 300 -- Duration for each effect in frames (5 seconds at 60 FPS)
local effectTimer = 0

-- Function to apply the current Worm trinket effect and stat boost
local function ApplyWormTrinket(player)
    -- Remove any existing Worm trinket
    for _, trinket in ipairs(wormTrinkets) do
        if player:HasTrinket(trinket) then
            player:TryRemoveTrinket(trinket)
        end
    end

    -- Give the player the current Worm trinket
    local currentTrinket = wormTrinkets[currentWormIndex]
    player:AddTrinket(currentTrinket)
    player:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, false, false, false, false) -- Simulate gulping the trinket

    -- Apply the stat boost
    local statBoost = wormStatBoosts[currentTrinket]
    if statBoost then
        if statBoost.Damage then player.Damage = player.Damage + statBoost.Damage end
        if statBoost.Tears then player.MaxFireDelay = player.MaxFireDelay - statBoost.Tears end
        if statBoost.Range then player.TearRange = player.TearRange + statBoost.Range end
        if statBoost.ShotSpeed then player.ShotSpeed = player.ShotSpeed + statBoost.ShotSpeed end
        if statBoost.TearHeight then player.TearHeight = player.TearHeight + statBoost.TearHeight end
        if statBoost.TearDelay then player.MaxFireDelay = player.MaxFireDelay + statBoost.TearDelay end
    end
end

-- Function to remove the current Worm trinket's stat boost
local function RemoveWormStatBoost(player, trinket)
    local statBoost = wormStatBoosts[trinket]
    if statBoost then
        if statBoost.Damage then player.Damage = player.Damage - statBoost.Damage end
        if statBoost.Tears then player.MaxFireDelay = player.MaxFireDelay + statBoost.Tears end
        if statBoost.Range then player.TearRange = player.TearRange - statBoost.Range end
        if statBoost.ShotSpeed then player.ShotSpeed = player.ShotSpeed - statBoost.ShotSpeed end
        if statBoost.TearHeight then player.TearHeight = player.TearHeight - statBoost.TearHeight end
        if statBoost.TearDelay then player.MaxFireDelay = player.MaxFireDelay - statBoost.TearDelay end
    end
end

-- Function to handle the update logic
local function OnGameUpdate()
    local player = Isaac.GetPlayer(0)

    if player:HasCollectible(AllfatherWorm) then
        effectTimer = effectTimer + 1

        if effectTimer >= effectDuration then
            -- Remove the current Worm trinket and its stat boost
            local currentTrinket = wormTrinkets[currentWormIndex]
            RemoveWormStatBoost(player, currentTrinket)
            player:TryRemoveTrinket(currentTrinket)

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
