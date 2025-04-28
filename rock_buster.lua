local BoneShaker = RegisterMod("MyMod", 1)
local CollectibleType = {
    BONE_SHAKER = Isaac.GetItemIdByName("Rock Buster")
}

-- Effekt bei Nutzung des Items
function BoneShaker:UseItem(_, rng, player, useFlags, activeSlot, varData)
    local game = Game()
    local room = game:GetRoom()

    -- Alle Rock-Typen explodieren lassen, inklusive Skull Rocks
    for i = 0, room:GetGridSize() - 1 do
        local grid = room:GetGridEntity(i)
        if grid then
            local gridType = grid:GetType()
            if gridType == GridEntityType.GRID_ROCK or gridType == GridEntityType.GRID_ROCK_ALT then
                grid:Destroy(true)
                game:BombExplosionEffects(room:GetGridPosition(i), 40, TearFlags.TEAR_NORMAL, Color(1, 1, 1, 1, 0.8, 0.8, 0.8), player, 0.5, false, false)
            end
        end
    end

    -- Existierende Türen auf Secret Rooms prüfen und öffnen
    local secretDoorOpened = false
    for doorSlot = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
        local door = room:GetDoor(doorSlot)
        if door and (door.TargetRoomType == RoomType.ROOM_SECRET or door.TargetRoomType == RoomType.ROOM_SUPERSECRET) then
            if not door:IsOpen() then
                door:Open()
                secretDoorOpened = true
            end
        end
    end

    -- Soundeffekt abspielen, wenn mindestens eine Secret Room Tür geöffnet wurde
    if secretDoorOpened then
        game:ShakeScreen(10)
        SFXManager():Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1.0, 0, false, 1.0)
    end

    return true
end

BoneShaker:AddCallback(ModCallbacks.MC_USE_ITEM, BoneShaker.UseItem, CollectibleType.BONE_SHAKER)
