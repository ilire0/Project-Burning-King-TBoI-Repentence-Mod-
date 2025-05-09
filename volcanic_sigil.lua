local mod = RegisterMod("MyMod", 1)

-- Define the item ID for the Volcanic Sigil
local VOLCANIC_SIGIL = Isaac.GetItemIdByName("Volcanic Sigil")

-- Room entry counter
local roomCounter = 0

-- Function to create multiple reddish-orange creeps
function mod:CreateVolcanicCreep(player)
    local room = Game():GetRoom()
    local centerPos = room:GetCenterPos()

    -- Offsets for multiple creeps
    local offsets = {
        Vector(0, 0),
        Vector(20, 20),
        Vector(-20, -20),
        Vector(20, -20),
        Vector(-20, 20),
        Vector(40, 0),
        Vector(-40, 0),
        Vector(0, 40),
        Vector(0, -40),
        Vector(30, 30),
        Vector(-30, -30)
    }

    -- Spawn multiple creeps with offsets
    for _, offset in ipairs(offsets) do
        local creepPos = centerPos + offset
        local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_LEMON_PARTY, 0, creepPos, Vector(0, 0), player):ToEffect()
        if creep then
            creep:SetTimeout(1000000)  -- Creep remains until room is cleared
            creep.SpriteScale = Vector(2, 2)  -- Standard size
            creep:Update()  -- Update to apply changes immediately
            creep.CollisionDamage = player.Damage / 2  -- Half of player's damage
            creep.Color = Color(1, 0.6, 0, 1, 0, 0, 0)  -- More orange color
        end
    end

    -- Spawn 2-4 random flames within the creeps
    local numFlames = math.random(2, 4)
    for i = 1, numFlames do
        local offset = Vector(math.random(-40, 40), math.random(-40, 40))
        local flamePos = centerPos + offset
        local flame = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, flamePos, Vector(0, 0), player)
        if flame then
            flame.CollisionDamage = player.Damage  -- Full damage
        end
    end
end

-- Callback for new room entry
function mod:OnNewRoom()
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(VOLCANIC_SIGIL) then
        roomCounter = roomCounter + 1

        local room = Game():GetRoom()
        if not room:IsClear() and roomCounter >= 3 then
            mod:CreateVolcanicCreep(player)
            roomCounter = 0  -- Reset counter after effect triggers
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)