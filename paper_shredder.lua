local mod = RegisterMod("MyMod", 1)
local game = Game()

-- Ensure the item is registered correctly
local PAPER_SHREDDER = Isaac.GetItemIdByName("Paper Shredder")

-- Table to keep track of removed cards
local removedCards = {}
local allCardsRemoved = false

-- List of all possible card IDs
local allCardIDs = {
    Card.CARD_FOOL, Card.CARD_MAGICIAN, Card.CARD_HIGH_PRIESTESS, Card.CARD_EMPRESS,
    Card.CARD_EMPEROR, Card.CARD_HIEROPHANT, Card.CARD_LOVERS, Card.CARD_CHARIOT,
    Card.CARD_JUSTICE, Card.CARD_HERMIT, Card.CARD_WHEEL_OF_FORTUNE, Card.CARD_STRENGTH,
    Card.CARD_HANGED_MAN, Card.CARD_DEATH, Card.CARD_TEMPERANCE, Card.CARD_DEVIL,
    Card.CARD_TOWER, Card.CARD_STARS, Card.CARD_MOON, Card.CARD_SUN,
    Card.CARD_JUDGEMENT, Card.CARD_WORLD, Card.CARD_CLUBS_2, Card.CARD_DIAMONDS_2,
    Card.CARD_SPADES_2, Card.CARD_HEARTS_2, Card.CARD_ACE_OF_CLUBS, Card.CARD_ACE_OF_DIAMONDS,
    Card.CARD_ACE_OF_SPADES, Card.CARD_ACE_OF_HEARTS, Card.CARD_JOKER, Card.CARD_CHAOS,
    Card.CARD_CREDIT, Card.CARD_RULES, Card.CARD_HUMANITY, Card.CARD_SUICIDE_KING,
    Card.CARD_GET_OUT_OF_JAIL, Card.CARD_QUESTIONMARK, Card.CARD_HOLY, Card.CARD_REVERSE_FOOL,
    Card.CARD_REVERSE_MAGICIAN, Card.CARD_REVERSE_HIGH_PRIESTESS, Card.CARD_REVERSE_EMPRESS,
    Card.CARD_REVERSE_EMPEROR, Card.CARD_REVERSE_HIEROPHANT, Card.CARD_REVERSE_LOVERS,
    Card.CARD_REVERSE_CHARIOT, Card.CARD_REVERSE_JUSTICE, Card.CARD_REVERSE_HERMIT,
    Card.CARD_REVERSE_WHEEL_OF_FORTUNE, Card.CARD_REVERSE_STRENGTH, Card.CARD_REVERSE_HANGED_MAN,
    Card.CARD_REVERSE_DEATH, Card.CARD_REVERSE_TEMPERANCE, Card.CARD_REVERSE_DEVIL,
    Card.CARD_REVERSE_TOWER, Card.CARD_REVERSE_STARS, Card.CARD_REVERSE_MOON,
    Card.CARD_REVERSE_SUN, Card.CARD_REVERSE_JUDGEMENT, Card.CARD_REVERSE_WORLD
}

-- Function to handle the use of Paper Shredder
function mod:UsePaperShredder()
    local player = Isaac.GetPlayer(0)
    local card = player:GetCard(0)

    if card ~= 0 then
        -- Add the card to the removed list
        removedCards[card] = true

        -- Remove the card from the player
        player:SetCard(0, 0)  -- Set the card slot to 0 to remove the card

        -- Check if all cards have been removed
        allCardsRemoved = true
        for _, cardID in ipairs(allCardIDs) do
            if not removedCards[cardID] then
                allCardsRemoved = false
                break
            end
        end

        -- Replace all instances of the card in the game
        mod:ReplaceCardInstances(card)

        return true
    end

    return false
end

-- Function to replace instances of a removed card
function mod:ReplaceCardInstances(cardToReplace)
    local entities = Isaac.GetRoomEntities()
    local rng = RNG()
    rng:SetSeed(Random(), 1)  -- Initialize RNG with a random seed

    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_TAROTCARD then
            local pickup = entity:ToPickup()
            if pickup and pickup.SubType == cardToReplace then
                -- Replace with a random pill
                local newPill = game:GetItemPool():GetPill(rng:Next())
                pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, newPill, true, false, false)
            end
        end
    end
end

-- Callback for when a card is spawned
function mod:OnCardSpawn(pickup)
    local rng = RNG()
    rng:SetSeed(Random(), 1)  -- Initialize RNG with a random seed

    if pickup.Variant == PickupVariant.PICKUP_TAROTCARD and removedCards[pickup.SubType] then
        -- Replace with a random pill
        local newPill = game:GetItemPool():GetPill(rng:Next())
        pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_PILL, newPill, true, false, false)
    end
end

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.UsePaperShredder, PAPER_SHREDDER)
mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, mod.OnCardSpawn, PickupVariant.PICKUP_TAROTCARD)