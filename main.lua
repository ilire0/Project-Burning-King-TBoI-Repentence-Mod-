local mod = RegisterMod("My Mod", 1)
local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local damagePotionDamage = 10

-- Item: Damage Potion

function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(damagePotion)
        local damageToAdd = damagePotionDamage * itemCount
        player.Damage = player.Damage + damageToAdd
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

-- Item: The Button
local redButton = Isaac.GetItemIdByName("The Button")
function mod:RedButtonUse(item)
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            entity:Kill()
        end
    end
    return {
        Discharge = true;
        Remove = false;
        ShowAnim = true;
    }
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, redButton)

-- Item: Pollen

local POLLEN_ITEM_ID = Isaac.GetItemIdByName("Pollen")
local POLLEN_POISON_CHANCE = 0.4
local POLLEN_POISON_LENGHT = 3
local ONE_INTERVAL_OF_POISION = 20

local game = Game()

function mod:PollenNewRoom()
    local playerCount = game:GetNumPlayers()
    
    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
        local copyCount = player:GetCollectibleNum(POLLEN_ITEM_ID)

        if copyCount > 0 then
            local rng = player:GetCollectibleRNG(POLLEN_ITEM_ID)
            local entities = Isaac.GetRoomEntities()
            for _, entity in ipairs(entities) do
                if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
                    if rng:RandomFloat() < POLLEN_POISON_CHANCE then
                        entity:AddPoison(EntityRef(player),POLLEN_POISON_LENGHT + (ONE_INTERVAL_OF_POISION * copyCount), player.Damage)
                    end
                end
            end
        end

    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.PollenNewRoom)


-- Item: Purgatory Flame

local PURGATORY_FLAME = Isaac.GetItemIdByName("Purgatory Flame") -- Hole die Item-ID
local PERMANENT_STATS = {
    Damage = 0.1,
    Speed = 0.02,
    Range = 0.25,
    Tears = 0.05,
    Luck = 0.1
}
local FIRE_ITEMS = {
    CollectibleType.COLLECTIBLE_BRIMSTONE,
    CollectibleType.COLLECTIBLE_SULFUR,
    CollectibleType.COLLECTIBLE_ABADDON,
    CollectibleType.COLLECTIBLE_MAW_OF_THE_VOID,
    CollectibleType.COLLECTIBLE_DARK_MATTER,
    CollectibleType.COLLECTIBLE_DEATHS_TOUCH,
    CollectibleType.COLLECTIBLE_SACRIFICIAL_DAGGER,
    CollectibleType.COLLECTIBLE_GOAT_HEAD,
    CollectibleType.COLLECTIBLE_PYROMANIAC,
    CollectibleType.COLLECTIBLE_HOT_BOMBS,
    CollectibleType.COLLECTIBLE_EXPLOSIVO,
    CollectibleType.COLLECTIBLE_SMELTER,
    CollectibleType.COLLECTIBLE_SULFURIC_ACID,
    CollectibleType.COLLECTIBLE_LOST_CONTACT,
    CollectibleType.COLLECTIBLE_JACOBS_LADDER,
    CollectibleType.COLLECTIBLE_CRICKETS_BODY,
    CollectibleType.COLLECTIBLE_BOBS_ROTTEN_HEAD,
    CollectibleType.COLLECTIBLE_COMPOUND_FRACTURE,
    CollectibleType.COLLECTIBLE_HAEMOLACRIA,
    CollectibleType.COLLECTIBLE_EPIC_FETUS,
    CollectibleType.COLLECTIBLE_DR_FETUS,
    CollectibleType.COLLECTIBLE_HOST_HAT,
    CollectibleType.COLLECTIBLE_SOY_MILK,
    CollectibleType.COLLECTIBLE_PARASITE,
    CollectibleType.COLLECTIBLE_IPECAC,
    CollectibleType.COLLECTIBLE_GHOST_PEPPER,
    CollectibleType.COLLECTIBLE_BIRDS_EYE,
    CollectibleType.COLLECTIBLE_URN_OF_SOULS,
    CollectibleType.COLLECTIBLE_JAR_OF_WISPS
}

function mod:UsePurgatoryFlame(item, rng, player, useFlags, activeSlot, varData)
    local room = Game():GetRoom()
    local fireCount = 0
    local blueFlameCount = 0

    for _, entity in pairs(Isaac.GetRoomEntities()) do
        -- Detect and remove all fires
        if entity.Type == EntityType.ENTITY_FIREPLACE then
            fireCount = fireCount + 1
            if entity.Variant == 1 then -- Blue flame
                blueFlameCount = blueFlameCount + 1
            end
            entity:Die()
        end

        -- Detect and remove Fire Mind flames
        if entity.Type == EntityType.ENTITY_EFFECT and 
           (entity.Variant == EffectVariant.RED_CANDLE_FLAME or 
            entity.Variant == EffectVariant.BLUE_FLAME) then
            fireCount = fireCount + 1
            entity:Remove()
        end
    end

    if fireCount > 0 then
        local data = player:GetData()
        data.FlamesPurged = (data.FlamesPurged or 0) + fireCount

        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
        player:AddCacheFlags(CacheFlag.CACHE_RANGE)
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:AddCacheFlags(CacheFlag.CACHE_LUCK)
        player:EvaluateItems()

        -- Schwarzes Herz oder Devil Room Bonus
        if data.FlamesPurged >= 50 then
            player:AddBlackHearts(1)
        end
     -- Nach 100 Flammen: Ein Fire Item erscheint
     if data.FlamesPurged >= 100 and data.FlamesPurged - fireCount < 100 then
        local pos = room:FindFreePickupSpawnPosition(player.Position, 0, true)
        local chosenItem = FIRE_ITEMS[math.random(#FIRE_ITEMS)]
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, chosenItem, pos, Vector(0, 0), nil)
    end
end

return true
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UsePurgatoryFlame, PURGATORY_FLAME)

-- **2. Stat-Boost Berechnung**
function mod:OnEvaluateCache(player, cacheFlag)
    local data = player:GetData()
    if data.FlamesPurged then
        if cacheFlag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage + (PERMANENT_STATS.Damage * data.FlamesPurged)
        end
        if cacheFlag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed + (PERMANENT_STATS.Speed * data.FlamesPurged)
        end
        if cacheFlag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange + (PERMANENT_STATS.Range * data.FlamesPurged)
        end
        if cacheFlag == CacheFlag.CACHE_FIREDELAY then
            player.MaxFireDelay = math.max(5, player.MaxFireDelay - (PERMANENT_STATS.Tears * data.FlamesPurged))
        end
        if cacheFlag == CacheFlag.CACHE_LUCK then
            player.Luck = math.min(13, player.Luck + (PERMANENT_STATS.Luck * data.FlamesPurged))
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnEvaluateCache)

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnEvaluateCache)
