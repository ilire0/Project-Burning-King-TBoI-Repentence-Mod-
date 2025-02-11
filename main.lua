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
local mod = RegisterMod("Purgatory Flame", 1)
local PURGATORY_FLAME = Isaac.GetItemIdByName("Purgatory Flame")

local PERMANENT_STATS = {
    Damage = 0.4,
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
    CollectibleType.COLLECTIBLE_GHOST_PEPPER,
    CollectibleType.COLLECTIBLE_BIRDS_EYE
}

function mod:UsePurgatoryFlame(item, rng, player, useFlags, activeSlot, varData)
    local room = Game():GetRoom()
    local fireCount = 0
    local blueFlameCount = 0

    local entities = Isaac.GetRoomEntities()

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

-- Gabriel Code / Do not change , because its for testing and nothing else , will delete everything below later on!
-- ###############################################################################################################################################

local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false) -- Exactly as in the xml. The second argument is if you want the Tainted variant.
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2") -- Exact path, with the "resources" folder as the root
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2") -- Exact path, with the "resources" folder as the root

function MyCharacterMod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.GiveCostumesOnInit)


--------------------------------------------------------------------------------------------------


local game = Game() -- We only need to get the game object once. It's good forever!
local DAMAGE_REDUCTION = 0.6
function MyCharacterMod:HandleStartingStats(player, flag)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    if flag == CacheFlag.CACHE_DAMAGE then
        -- Every time the game reevaluates how much damage the player should have, it will reduce the player's damage by DAMAGE_REDUCTION, which is 0.6
        player.Damage = player.Damage - DAMAGE_REDUCTION
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MyCharacterMod.HandleStartingStats)

function MyCharacterMod:HandleHolyWaterTrail(player)
    if player:GetPlayerType() ~= gabrielType then
        return -- End the function early. The below code doesn't run, as long as the player isn't Gabriel.
    end

    -- Every 4 frames. The percentage sign is the modulo operator, which returns the remainder of a division operation!
    if game:GetFrameCount() % 4 == 0 then
        -- Vector.Zero is the same as Vector(0, 0). It is a constant!
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, player.Position, Vector.Zero, player):ToEffect()
        creep.SpriteScale = Vector(0.5, 0.5) -- Make it smaller!
        creep:Update() -- Update it to get rid of the initial red animation that lasts a single frame.
    end
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, MyCharacterMod.HandleHolyWaterTrail)

--------------------------------------------------------------------------------------------------

local TAINTED_GABRIEL_TYPE = Isaac.GetPlayerTypeByName("Gabriel", true)
local HOLY_OUTBURST_ID = Isaac.GetItemIdByName("Holy Outburst")
local game = Game()

---@param player EntityPlayer
function MyCharacterMod:TaintedGabrielInit(player)
    if player:GetPlayerType() ~= TAINTED_GABRIEL_TYPE then
        return
    end

    player:SetPocketActiveItem(HOLY_OUTBURST_ID, ActiveSlot.SLOT_POCKET, true)

    local pool = game:GetItemPool()
    pool:RemoveCollectible(HOLY_OUTBURST_ID)
end

MyCharacterMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MyCharacterMod.TaintedGabrielInit)

function MyCharacterMod:HolyOutburstUse(_, _, player)
    local spawnPos = player.Position

    local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER, 0, spawnPos, Vector.Zero, player):ToEffect()
    creep.Scale = 2
    creep:Update()

    return true
end

MyCharacterMod:AddCallback(ModCallbacks.MC_USE_ITEM, MyCharacterMod.HolyOutburstUse, HOLY_OUTBURST_ID)