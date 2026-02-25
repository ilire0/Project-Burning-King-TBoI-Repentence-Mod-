local Mod = PBK
-- The Pope's Pocket-Watch Trinket
local PopesWatch = {}
PopesWatch.TrinketID = Isaac.GetTrinketIdByName("The Pope's Pocket-Watch")
local timer = 0

function PopesWatch:Update(player)
    if player:HasTrinket(PopesWatch.TrinketID) then
        timer = timer + 1
        if timer >= 60 * 30 then -- 60 seconds * 30 FPS
            timer = 0
            -- Trigger The Sun card effect
            -- Heal Isaac to full hearts
            player:AddHearts(player:GetMaxHearts() - player:GetHearts())
            -- Optional extra damage burst
            player:TakeDamage(-1, DamageFlag.DAMAGE_NOKILL, EntityRef(player), 0)

            -- Spawn the Sun card effect
            local sunCard = Isaac.GetCardIdByName("The Sun")
            player:UseCard(sunCard, UseFlag.USE_NOANIM | UseFlag.USE_NOHUD, -1)
        end
    end
end

Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    PopesWatch:Update(player)
end)
