-- Stale Burrito Active Item Implementation
local mod = PBK
local StaleBurrito = {}

-- Item ID (replace with your actual item name from items.xml)
StaleBurrito.ITEM_ID = Isaac.GetItemIdByName("Stale Burrito")

-- Called when the item is used
function StaleBurrito:OnUse(_, rng, player, flags)
    -- Heal half a red heart if not at full red heart health
    if player:GetHearts() < player:GetMaxHearts() then
        if player.AddHearts ~= nil then
            player:AddHearts(1) -- Half a red heart
        else
            -- Fallback for older APIs
            player:SetHearts(player:GetHearts() + 1)
        end
    end

    -- Spawn a friendly blue fly
    player:AddBlueFlies(1, player.Position, player)

    -- Play a gulp sound
    SFXManager():Play(SoundEffect.SOUND_VAMP_GULP)

    return true
end

-- Register the item use callback
mod:AddCallback(ModCallbacks.MC_USE_ITEM, StaleBurrito.OnUse, StaleBurrito.ITEM_ID)
