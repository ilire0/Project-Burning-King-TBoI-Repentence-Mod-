local mod = RegisterMod("MyMod", 1)
local POLLEN_ITEM_ID = Isaac.GetItemIdByName("Pollen")
local POLLEN_POISON_CHANCE = 0.4
local POLLEN_POISON_LENGTH = 3
local ONE_INTERVAL_OF_POISON = 20
local POLLEN_CLOUD_LIFESPAN = 150
local POLLEN_CLOUD_VARIANT = EffectVariant.SMOKE_CLOUD

local game = Game()

function mod:PollenNewRoom()
    local room = game:GetRoom()
    local playerCount = game:GetNumPlayers()

    for playerIndex = 0, playerCount - 1 do
        local player = Isaac.GetPlayer(playerIndex)
        local copyCount = player:GetCollectibleNum(POLLEN_ITEM_ID)

        if copyCount > 0 then
            local rng = player:GetCollectibleRNG(POLLEN_ITEM_ID)
            local entities = Isaac.GetRoomEntities()

            -- Poison 40% of enemies
            for _, entity in ipairs(entities) do
                if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
                    if rng:RandomFloat() < POLLEN_POISON_CHANCE then
                        entity:AddPoison(EntityRef(player), POLLEN_POISON_LENGTH + (ONE_INTERVAL_OF_POISON * copyCount), player.Damage)
                    end
                end
            end

            -- Spawn pollen clouds at random positions in the room
            local numClouds = 1 + rng:RandomInt(2) + copyCount - 1
            for i = 1, numClouds do
                local randomPos = room:GetRandomPosition(5)  -- avoid spawning on rocks or pits
                local velocity = Vector.FromAngle(rng:RandomInt(360)) * (0.5 + 0.2 * copyCount)

                local cloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, POLLEN_CLOUD_VARIANT, 0, randomPos, velocity, player):ToEffect()
                cloud:GetData().IsPollenCloud = true
                cloud:GetData().Owner = player
                cloud:GetData().Life = POLLEN_CLOUD_LIFESPAN
                cloud:Update()
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.PollenNewRoom)

function mod:UpdatePollenCloud(effect)
    local data = effect:GetData()
    if not data.IsPollenCloud then return end

    data.Life = data.Life - 1
    if data.Life <= 0 then
        effect:Remove()
        return
    end

    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() and entity.Position:Distance(effect.Position) < 30 then
            entity:AddPoison(EntityRef(data.Owner), 30, data.Owner.Damage * 0.5)
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.UpdatePollenCloud, POLLEN_CLOUD_VARIANT)
