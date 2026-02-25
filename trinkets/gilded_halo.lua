local Mod = PBK
-- Gilded Halo Trinket
local GildedHalo = {}

GildedHalo.TrinketID = Isaac.GetTrinketIdByName("Gilded Halo")

function GildedHalo:Evaluate(player)
    local brokenHearts = player:GetBrokenHearts()

    if brokenHearts > 0 then
        player.Damage = player.Damage + 0.5 * brokenHearts
    else
        if math.random() < 0.1 then -- 10% chance
            local room = Game():GetRoom()
            local spawnType = math.random(1, 2)
            if spawnType == 1 then
                Isaac.Spawn(SlotVariant.CONFESSIONAL, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
            else
                Isaac.Spawn(SlotVariant.BEGGAR, 0, 0, room:GetCenterPos(), Vector(0, 0), nil)
            end
        end
    end
end

-- Evaluate on cache update (damage)
Mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
    if player:HasTrinket(GildedHalo.TrinketID) then
        GildedHalo:Evaluate(player)
    end
end)
