-- Item: Purgatory Flame
local mod = RegisterMod("Purgatory Flame", 1)
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

-- Damage Potion Effect
local damagePotion = Isaac.GetItemIdByName("Damage Potion")
local damagePotionDamage = 10
function mod:EvaluateCache(player, cacheFlags)
    if cacheFlags & CacheFlag.CACHE_DAMAGE == CacheFlag.CACHE_DAMAGE then
        local itemCount = player:GetCollectibleNum(damagePotion)
        local damageToAdd = damagePotionDamage * itemCount
        player.Damage = player.Damage + damageToAdd
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.EvaluateCache)

-- The Button Use Effect
local redButton = Isaac.GetItemIdByName("The Button")
function mod:RedButtonUse()
    local roomEntities = Isaac.GetRoomEntities()
    for _, entity in ipairs(roomEntities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            entity:Kill()
        end
    end
    return true -- Correct return for MC_USE_ITEM
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.RedButtonUse, redButton)

-- Pollen Effect
local POLLEN_ITEM_ID = Isaac.GetItemIdByName("Pollen")
local POLLEN_POISON_CHANCE = 0.4
local POLLEN_POISON_LENGTH = 3
local ONE_INTERVAL_OF_POISON = 20
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
                        entity:AddPoison(EntityRef(player), POLLEN_POISON_LENGTH + (ONE_INTERVAL_OF_POISON * copyCount), player.Damage)
                    end
                end
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.PollenNewRoom)

--- Loaded Die Effect
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

-- Optic Bomb Effect
local opticBomb = Isaac.GetItemIdByName("Optic Bomb")
function mod:onUpdate(player)
    if player:HasCollectible(opticBomb) then
        player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_PYROMANIAC)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.onUpdate)

function mod:onEnemyHit(entity, amount, flags, source, countdown)
    local player = source.Entity and source.Entity:ToPlayer()
    if player and player:HasCollectible(opticBomb) then
        entity:AddBurn(EntityRef(entity), 30, player.Damage * 0.1)
    end
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.onEnemyHit)

function mod:onEnemyDeath(entity)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(opticBomb) then
        local damage = player.Damage * 20
        local radius = math.min(100 + (player.Damage * 10), 300)
        Game():BombExplosionEffects(entity.Position, damage, BombVariant.BOMB_NORMAL, Color(1, 0.5, 0, 1), player, 1, true, false)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mod.onEnemyDeath)

print("My Mod loaded successfully!")

-- Character: Gabriel
local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")

function mod:OnGabrielInit(player)
    if player:GetPlayerType() == gabrielType then
        -- Add costumes
        player:AddNullCostume(hairCostume)
        player:AddNullCostume(stolesCostume)
        
        -- Give "Purgatory Flame" as a starting pocket item
        player:AddCollectible(PURGATORY_FLAME, 0, false)
        
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

function mod:HandleStartingStats(player, flag)
    if player:GetPlayerType() ~= gabrielType then return end
    if flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + 0.6
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.HandleStartingStats)


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
    creep.Scale = 2
    creep:Update()
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.HolyOutburstUse, holyOutburstID)