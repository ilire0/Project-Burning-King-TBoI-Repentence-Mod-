local BorrowedTimeMod = RegisterMod("Borrowed Time", 1)
local ItemId = Isaac.GetItemIdByName("Borrowed Time")
local borrowedData = {
    temporaryItems = {},
    originalActives = {}
}

-- Wird verwendet, um ein temporäres Item zu geben
function BorrowedTimeMod:UseBorrowedTime(_, rng, player, flags)
    local room = Game():GetRoom()
    local itemPool = Game():GetItemPool()
    local currentPool = itemPool:GetPoolForRoom(Game():GetLevel():GetCurrentRoomIndex(), 0)
    local randomItem = itemPool:GetCollectible(currentPool, false, rng:Next())

    if randomItem ~= 0 then
        local activeSlot = ActiveSlot.SLOT_PRIMARY
        local config = Isaac.GetItemConfig():GetCollectible(randomItem)

        -- Wenn es ein aktives Item ist, speichere das Original und ersetze es
        if config.Type == ItemType.ITEM_ACTIVE then
            local originalActive = player:GetActiveItem(activeSlot)
            if originalActive ~= 0 then
                table.insert(borrowedData.originalActives, originalActive)
                player:RemoveCollectible(originalActive)
            end
            player:SetActiveCharge(0, activeSlot)
        end

        player:AddCollectible(randomItem, 0, false)
        table.insert(borrowedData.temporaryItems, randomItem)
    end

    return true
end
BorrowedTimeMod:AddCallback(ModCallbacks.MC_USE_ITEM, BorrowedTimeMod.UseBorrowedTime, ItemId)

-- Wird aufgerufen, wenn ein neuer Raum betreten wird
function BorrowedTimeMod:OnNewRoom()
    local player = Isaac.GetPlayer(0)

    -- Entferne alle temporären Items
    for _, item in ipairs(borrowedData.temporaryItems) do
        player:RemoveCollectible(item)
    end

    -- Stelle originale aktive Items wieder her
    for _, originalActive in ipairs(borrowedData.originalActives) do
        player:AddCollectible(originalActive, 0, false)
    end

    -- Reset der Daten
    borrowedData.temporaryItems = {}
    borrowedData.originalActives = {}
end
BorrowedTimeMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, BorrowedTimeMod.OnNewRoom)
