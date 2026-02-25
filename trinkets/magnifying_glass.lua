local Mod = PBK
local MagnifyingGlass = {}
MagnifyingGlass.TrinketID = Isaac.GetTrinketIdByName("Magnifying Glass")
MagnifyingGlass.BeamDuration = 30 -- frames

function MagnifyingGlass:Update(player)
    if player:HasTrinket(MagnifyingGlass.TrinketID) then
        local vel = player.Velocity:Length()
        if vel < 0.1 then
            local nearestEnemy = nil
            local closestDist = 9999
            for _, enemy in ipairs(Isaac.GetRoomEntities()) do
                if enemy:IsActiveEnemy() then
                    local dist = (enemy.Position - player.Position):Length()
                    if dist < closestDist then
                        closestDist = dist
                        nearestEnemy = enemy
                    end
                end
            end
            if nearestEnemy then
                local laser = EntityLaser.ShootAngle(2, player.Position,
                    (nearestEnemy.Position - player.Position):GetAngleDegrees(), 5, Vector(0, 0), player)
                laser:AddTearFlags(TearFlags.TEAR_PIERCING)
            end
        end
    end
end

Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    MagnifyingGlass:Update(player)
end)
