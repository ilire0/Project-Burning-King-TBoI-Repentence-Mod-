local mod = RegisterMod("MyMod", 1)
local PSEUDOTHEISM = Isaac.GetItemIdByName("Pseudotheism")

function mod:OnNewRoom()
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(PSEUDOTHEISM) then
        local room = Game():GetRoom()
        if room:GetType() == RoomType.ROOM_DEVIL then
            -- Replace devil statue with angel statue
            local entities = Isaac.GetRoomEntities()
            for _, entity in ipairs(entities) do
                if entity.Type == EntityType.ENTITY_EFFECT and entity.Variant == EffectVariant.DEVIL then
                    entity:Remove()
                    local center = room:GetCenterPos()
                    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, 0, center, Vector(0, 0), nil)
                end
            end

            -- Replace devil deal items with items from all pools, favoring angel items slightly more
            local itemPool = Game():GetItemPool()
            for _, entity in ipairs(entities) do
                if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE then
                    local roll = math.random()
                    local poolType

                    if roll < 0.45 then
                        poolType = ItemPoolType.POOL_ANGEL
                    elseif roll < 0.85 then
                        poolType = ItemPoolType.POOL_DEVIL
                    else
                        poolType = ItemPoolType.POOL_NULL
                    end

                    local newItem = itemPool:GetCollectible(poolType, false, entity.InitSeed)
                    entity:ToPickup():Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, newItem, true, false, false)
                end
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)