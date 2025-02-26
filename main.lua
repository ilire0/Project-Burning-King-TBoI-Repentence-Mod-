-- Register the mod (Only once!)
local mod = RegisterMod("My Mod", 1)

-- Constants for stat modifications
local PERMANENT_STATS = {
    Damage = 0.5,  -- Adjust as needed
    Tears = 0.25,  -- Adjust as needed
}

-- Table to store player data
mod.Data = {}

-- Function to initialize player data
function mod:OnPlayerInit(player)
    local playerID = player:GetPlayerType()
    mod.Data[playerID] = mod.Data[playerID] or { FlamesPurged = 0 }
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnPlayerInit)

-- Function to handle stat modifications
function mod:OnEvaluateCache(player, cacheFlag)
    local data = mod.Data[player:GetPlayerType()]
    if not data then return end

    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + (PERMANENT_STATS.Damage * data.FlamesPurged)
    end
    
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        -- Adjusting Tears correctly
        local newTears = player.Tears + (PERMANENT_STATS.Tears * data.FlamesPurged)
        player.Tears = math.max(0.5, newTears) -- Ensures fire rate doesn't go too low
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

function mod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then return end
    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumesOnInit)

function mod:HandleStartingStats(player, flag)
    if player:GetPlayerType() ~= gabrielType then return end
    if flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage - 0.6
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.HandleStartingStats)

function mod:HandleHolyWaterTrail(player)
    if player:GetPlayerType() ~= gabrielType then return end
    if Game():GetFrameCount() % 4 == 0 then
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER_TRAIL, 0, player.Position, Vector.Zero, player):ToEffect()
        creep.SpriteScale = Vector(0.5, 0.5)
        creep:Update()
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.HandleHolyWaterTrail)

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