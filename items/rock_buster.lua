local BoneShaker = RegisterMod("MyMod", 1)
local CollectibleType = {
    BONE_SHAKER = Isaac.GetItemIdByName("Rock Buster")
}

function BoneShaker:UseItem(_, rng, player, useFlags, activeSlot, varData)
    local game = Game()
    local room = game:GetRoom()

    -- Alle Rock-Typen explodieren lassen
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

    local secretDoorFound = false
    local secretDoorOpened = false

    for doorSlot = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
        local door = room:GetDoor(doorSlot)
        if door then
            if (door.TargetRoomType == RoomType.ROOM_SECRET or door.TargetRoomType == RoomType.ROOM_SUPERSECRET) then
                secretDoorFound = true

                if not door:IsOpen() then
                    
                    -- Position der Tür herausfinden
                    local doorPos = door.Position
                    local gridIndex = room:GetGridIndex(doorPos)

                    -- Das Grid an der Tür holen
                    local gridEntity = room:GetGridEntity(gridIndex)

                    if gridEntity then
                        gridEntity:Destroy(true)
                        secretDoorOpened = true
                    end
                end
            end
        end
    end

    if secretDoorOpened then
        game:ShakeScreen(10)
        SFXManager():Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1.0, 0, false, 1.0)
    end

    return true
end

BoneShaker:AddCallback(ModCallbacks.MC_USE_ITEM, BoneShaker.UseItem, CollectibleType.BONE_SHAKER)
