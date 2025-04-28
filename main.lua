local mod = RegisterMod("MyMod", 1)

-- Require other Lua files and capture the returned item ID

require("bee_buster")
require("purgatory_flame")
require("chirping_alarm")
require("damage_potion")
require("loaded_die")
require("optic_bomb")
require("paper_shredder")
require("pollen")
require("pyro_mantle")
require("smouldering_dice")
require("the_button")
require("duality_mirror")
require("Pseudotheism")
require("rule_of_power")
require("dammys_dilemma")
require("ash_crown")
require("allfather_worm")
require("battery_booster")
require("volcanic_sigil")
require("covenant_of_ashes")
require("hollow_echo")
require("rock_buster")

local PURGATORY_FLAME = Isaac.GetItemIdByName("Purgatory Flame")

local PERMANENT_STATS = {
    Damage = 0.1,
    Speed = 0.02,
    Range = 0.25,
    Tears = 0.1,
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
    CollectibleType.COLLECTIBLE_GHOST_PEPPER,
    CollectibleType.COLLECTIBLE_BIRDS_EYE,
    CollectibleType.COLLECTIBLE_BLACK_CANDLE,
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
    CollectibleType.COLLECTIBLE_URN_OF_SOULS,
    CollectibleType.COLLECTIBLE_JAR_OF_WISPS,
    CollectibleType.COLLECTIBLE_BLACK_CANDLE,
    CollectibleType.COLLECTIBLE_RED_CANDLE,
}

function mod:UsePurgatoryFlame(item, rng, player, useFlags, activeSlot, varData)
    local room = Game():GetRoom()
    local fireCount = 0
    local blueFlameCount = 0

    local entities = Isaac.GetRoomEntities()
    local sfx = SFXManager()

    -- Zuerst alle Flammen zählen, bevor sie zerstört werden
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_FIREPLACE then
            fireCount = fireCount + 1
            if entity.Variant == 1 then -- Blaue Flamme
                blueFlameCount = blueFlameCount + 1
            end
        elseif entity.Type == EntityType.ENTITY_EFFECT and 
              (entity.Variant == EffectVariant.RED_CANDLE_FLAME or 
               entity.Variant == EffectVariant.BLUE_FLAME) then
            fireCount = fireCount + 1
        end
    end

    -- Dann alle Flammen entfernen
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_FIREPLACE or 
           (entity.Type == EntityType.ENTITY_EFFECT and 
            (entity.Variant == EffectVariant.RED_CANDLE_FLAME or 
             entity.Variant == EffectVariant.BLUE_FLAME)) then
                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, entity.Position, Vector(0, 0), nil)
                sfx:Play(SoundEffect.SOUND_FIREDEATH_HISS, 1.0, 0, false, 1.0)
                entity:Remove()
        end
    end

    if fireCount > 0 then
        local data = player:GetData()
        data.FlamesPurged = (data.FlamesPurged or 0) + fireCount

        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SPEED | CacheFlag.CACHE_RANGE | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_LUCK)
        player:EvaluateItems()

        -- Schwarzes Herz für jede 50. Flamme
        local previousFlames = data.FlamesPurged - fireCount
        local newFlames = data.FlamesPurged

        for i = previousFlames + 1, newFlames do
            if i % 50 == 0 then
                player:AddBlackHearts(1)
            end
        end

        -- Nach 100 Flammen ein Fire-Item
        if newFlames >= 100 and previousFlames < 100 then
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
            local newLuck = player.Luck + (PERMANENT_STATS.Luck * data.FlamesPurged)
            player.Luck = math.min(newLuck, 13) -- Luck ist auf 13 gecappt
        end
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnEvaluateCache)

-- Character: Gabriel
local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")

function mod:OnGabrielInit(player)
    if player:GetPlayerType() == gabrielType then
        -- Add costumes
        player:AddNullCostume(hairCostume)
        player:AddNullCostume(stolesCostume)
        
        -- Give "Purgatory Flame" as a starting active item
        player:AddCollectible(PURGATORY_FLAME, 0, true)  -- Ensure it's added to the active slot
        player:FullCharge(ActiveSlot.SLOT_PRIMARY)  -- Fully charge the primary active slot
        
        -- Remove "Purgatory Flame" from the item pool so it can't be found normally
        Game():GetItemPool():RemoveCollectible(PURGATORY_FLAME)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnGabrielInit)

function mod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then return end
    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumesOnInit)

-- Character: Tainted Gabriel
local taintedGabrielType = Isaac.GetPlayerTypeByName("Gabriel", true)
local holyOutburstID = Isaac.GetItemIdByName("Holy Outburst")

function mod:TaintedGabrielInit(player)
    if player:GetPlayerType() ~= taintedGabrielType then return end
    player:SetPocketActiveItem(holyOutburstID, ActiveSlot.SLOT_POCKET, true)
    Game():GetItemPool():RemoveCollectible(holyOutburstID)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.TaintedGabrielInit)

function mod:HolyOutburstUse(_, _, player)
    local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER, 0, player.Position, Vector.Zero, player):ToEffect()
    
    if creep then  -- Check if creep is not nil
        creep.Scale = 2
        creep:Update()
    end
    
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.HolyOutburstUse, holyOutburstID)