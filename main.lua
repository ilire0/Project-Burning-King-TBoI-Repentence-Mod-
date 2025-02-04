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