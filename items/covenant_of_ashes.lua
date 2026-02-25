local mod = PBK
-- Define the item ID for Covenant of Ashes
local CovenantOfAshes = Isaac.GetItemIdByName("Covenant of Ashes")

-- Function to handle the use of the item
local function UseCovenantOfAshes(_, _, player)
    local player = Isaac.GetPlayer()

    if player.GetMaxHearts then
        local redHearts = player:GetMaxHearts() / 2 -- Each heart container is 2 half-hearts
        local damageBoost = 0.5                     -- Damage boost per heart
        local rangeBoost = 1.0                      -- Range boost per heart

        if redHearts > 0 then
            -- Convert all red heart containers to black hearts
            player:AddMaxHearts(-redHearts * 2)
            player:AddBlackHearts(redHearts * 2)

            -- Apply permanent damage and range boost
            player.Damage = player.Damage + (redHearts * damageBoost)
            player.TearRange = player.TearRange + (redHearts * rangeBoost)
        end

        -- Play the flame extinguish sound
        local sfx = SFXManager()
        sfx:Play(SoundEffect.SOUND_FLAME_BURST, 1.0, 0, false, 1.0)

        -- Remove the item after use
        player:RemoveCollectible(CovenantOfAshes)
    end

    return true
end

-- Add a callback for when the item is used

mod:AddCallback(ModCallbacks.MC_USE_ITEM, UseCovenantOfAshes, CovenantOfAshes)
