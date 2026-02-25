local HollowEcho = PBK
local ItemId = Isaac.GetItemIdByName("Hollow Echo")
local EchoChamberId = CollectibleType.COLLECTIBLE_ECHO_CHAMBER

local lastCardUsed = nil
local lastPillUsed = nil
local lastEchoedCard = nil

function HollowEcho:useItem()
    local player = Isaac.GetPlayer(0)

    -- Check if Echo Chamber is held and 50% chance to reuse the last used card
    if player:HasCollectible(EchoChamberId) and lastEchoedCard and math.random() < 0.5 then
        -- Use the last echoed card with normal effect
        player:UseCard(lastEchoedCard)
    else
        -- 50% chance to reuse the last used card
        if lastCardUsed and math.random() < 0.5 then
            player:UseCard(lastCardUsed)
        end

        -- 50% chance to reuse the last used pill
        if lastPillUsed and math.random() < 0.5 then
            player:UsePill(lastPillUsed, PillColor.PILL_NULL)
        end
    end
end

-- Callback for when a card is used
function HollowEcho:onUseCard(card)
    lastCardUsed = card
end

-- Callback for when a pill is used
function HollowEcho:onUsePill(pill)
    lastPillUsed = pill
end

-- Reset the last used card and pill at the start of a new floor
function HollowEcho:onNewLevel()
    lastCardUsed = nil
    lastPillUsed = nil
    lastEchoedCard = nil
end

-- Register callbacks
HollowEcho:AddCallback(ModCallbacks.MC_USE_ITEM, HollowEcho.useItem, ItemId)
HollowEcho:AddCallback(ModCallbacks.MC_USE_CARD, HollowEcho.onUseCard)
HollowEcho:AddCallback(ModCallbacks.MC_USE_PILL, HollowEcho.onUsePill)
HollowEcho:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, HollowEcho.onNewLevel)
