local mod = RegisterMod("PBK", 1)
require("items.purgatory_flame")

-------------------------------------------------
-- CHARACTER SETUP
-------------------------------------------------

local gabrielType = Isaac.GetPlayerTypeByName("King Manasse", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/km_crown.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/km_body.anm2")
local PURGATORY_FLAME = Isaac.GetItemIdByName("Purgatory Flame")

-------------------------------------------------
-- BIRTHRIGHT CONFIG
-------------------------------------------------

local EXPLOSION_DAMAGE_BUFF = 2.0 -- flat damage bonus

-- Track per-room buff
local roomBuffActive = {}

-------------------------------------------------
-- GABRIEL INIT
-------------------------------------------------

function mod:OnGabrielInit(player)
    if player:GetPlayerType() == gabrielType then
        player:AddNullCostume(hairCostume)
        player:AddNullCostume(stolesCostume)
        player:AddCollectible(PURGATORY_FLAME, 0, true)
        player:FullCharge(ActiveSlot.SLOT_PRIMARY)
        Game():GetItemPool():RemoveCollectible(PURGATORY_FLAME)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnGabrielInit)

-------------------------------------------------
-- EXPLOSION IMMUNITY + ROOM BUFF
-------------------------------------------------

function mod:OnPlayerTakeDamage(entity, amount, flags, source, countdown)
    local player = entity:ToPlayer()
    if not player then return end
    if player:GetPlayerType() ~= gabrielType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    -- Explosion damage check
    if flags & DamageFlag.DAMAGE_EXPLOSION ~= 0 then
        local seed = player.InitSeed

        -- Activate buff once per room
        if not roomBuffActive[seed] then
            roomBuffActive[seed] = true

            player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
            player:EvaluateItems()
        end

        return false -- Full explosion immunity
    end
end

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.OnPlayerTakeDamage)

-------------------------------------------------
-- DAMAGE CACHE
-------------------------------------------------

function mod:OnEvaluateCache(player, cacheFlag)
    if cacheFlag ~= CacheFlag.CACHE_DAMAGE then return end
    if player:GetPlayerType() ~= gabrielType then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return end

    local seed = player.InitSeed

    if roomBuffActive[seed] then
        player.Damage = player.Damage + EXPLOSION_DAMAGE_BUFF
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnEvaluateCache)

-------------------------------------------------
-- RESET BUFF ON NEW ROOM
-------------------------------------------------

function mod:OnNewRoom()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:GetPlayerType() == gabrielType then
            local seed = player.InitSeed
            if roomBuffActive[seed] then
                roomBuffActive[seed] = nil
                player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
                player:EvaluateItems()
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
