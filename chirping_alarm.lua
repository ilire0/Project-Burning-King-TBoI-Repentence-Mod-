local mod = RegisterMod("MyMod", 1)
local game = Game()

local CHIRPING_ALARM_ITEM = Isaac.GetItemIdByName("Chirping Alarm")

-- Function to spawn a halo of fire around Isaac
local function SpawnHaloOfFire(player)
    local baseNumFires = 3  -- Base number of fires
    local numItems = player:GetCollectibleNum(CHIRPING_ALARM_ITEM)  -- Number of times the item is picked up
    local numFires = baseNumFires * numItems  -- Total number of fires
    local radius = 70  -- Radius for the circular path

    for i = 1, numFires do
        local angle = (i / numFires) * 2 * math.pi
        local offset = Vector(math.cos(angle) * radius, math.sin(angle) * radius)
        local firePos = player.Position + offset

        -- Spawn a fire effect
        local fire = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, firePos, Vector(0, 0), player)
        fire:GetData().isChirpingAlarmFire = true
        fire:GetData().angle = angle  -- Store the initial angle for rotation
        fire.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES  -- Only collide with enemies
        fire:ClearEntityFlags(EntityFlag.FLAG_RENDER_FLOOR)  -- Ensure it doesn't interact with the floor
    end
end

-- Function to update the halo of fire
local function UpdateHaloOfFire(player)
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:GetData().isChirpingAlarmFire then
            local radius = 70
            local speed = 0.12  -- Speed of rotation
            entity:GetData().angle = entity:GetData().angle + speed
            local angle = entity:GetData().angle
            local offset = Vector(math.cos(angle) * radius, math.sin(angle) * radius)
            entity.Position = player.Position + offset
        end
    end
end

-- Function to handle room entry
function mod:OnNewRoom()
    local player = Isaac.GetPlayer(0)  -- Assuming single player for simplicity

    if player:HasCollectible(CHIRPING_ALARM_ITEM) then
        -- Remove existing fires
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity:GetData().isChirpingAlarmFire then
                entity:Remove()
            end
        end

        -- Spawn new halo of fire
        SpawnHaloOfFire(player)
    end
end

-- Function to handle update
function mod:OnUpdate()
    local player = Isaac.GetPlayer(0)  -- Assuming single player for simplicity

    if player:HasCollectible(CHIRPING_ALARM_ITEM) then
        UpdateHaloOfFire(player)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnUpdate)