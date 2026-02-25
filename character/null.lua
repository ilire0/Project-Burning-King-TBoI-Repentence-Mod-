local mod = RegisterMod("NulCharacter", 1)

--==================================================
-- CONSTANTS
--==================================================

local game = Game()
local sfx = SFXManager()

local nulType = Isaac.GetPlayerTypeByName("Nul", false)
local headCostume = Isaac.GetCostumeIdByPath("gfx/characters/nul_head.anm2")

local BLACK_TEAR_COLOR = Color(0.1, 0.1, 0.1, 1, 0, 0, 0)
local STATIC_COLOR = Color(0.5, 0.5, 0.5, 0.8, 0.2, 0.2, 0.2)

local IDLE_THRESHOLD = 90

--==================================================
-- PLAYER INIT
--==================================================

function mod:OnPlayerInit(player)
    if player:GetPlayerType() ~= nulType then return end

    player:AddNullCostume(headCostume)

    player:AddCacheFlags(CacheFlag.CACHE_TEARCOLOR | CacheFlag.CACHE_SPEED)
    player:EvaluateItems()
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnPlayerInit)

--==================================================
-- CACHE
--==================================================

function mod:OnEvaluateCache(player, cacheFlag)
    if player:GetPlayerType() ~= nulType then return end

    if cacheFlag == CacheFlag.CACHE_TEARCOLOR then
        player.TearColor = BLACK_TEAR_COLOR
    end

    if cacheFlag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + 0.1
    end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OnEvaluateCache)

--==================================================
-- SAFE TELEPORT FUNCTION
--==================================================

local function SafeBlinkTeleport(player)
    local room = game:GetRoom()
    local attempts = 10

    for i = 1, attempts do
        local newPos = room:FindFreePickupSpawnPosition(player.Position, 40, true)

        if room:GetGridCollisionAtPos(newPos) == GridCollisionClass.COLLISION_NONE then
            player.Position = newPos
            return
        end
    end
end

--==================================================
-- PLAYER UPDATE
--==================================================

function mod:OnPlayerUpdate(player)
    if player:GetPlayerType() ~= nulType then return end

    local data = player:GetData()
    local sprite = player:GetSprite()

    if data.IdleFrames == nil then
        data.IdleFrames = 0
    end

    if data.IsIdleGlitching == nil then
        data.IsIdleGlitching = false
    end

    -------------------------------------------------
    -- SAFETY RESET
    -------------------------------------------------
    if not data.IsIdleGlitching then
        sprite.Color = Color(1, 1, 1, 1, 0, 0, 0)
        sprite.Scale = Vector(1, 1)
        sprite.Offset = Vector(0, 0)
    end

    -------------------------------------------------
    -- A. STATIC TRAIL WHILE MOVING (100% SAFE)
    -------------------------------------------------
    if player.Velocity:Length() > 0.2 then
        if game:GetFrameCount() % 3 == 0 then
            local creep = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.DARK_BALL_SMOKE_PARTICLE,
                0,
                player.Position,
                Vector.Zero,
                player -- Player is the spawner
            ):ToEffect()

            if creep then
                creep.SpriteScale = Vector(0.8, 0.8)
                creep:SetTimeout(40)
                creep.Color = STATIC_COLOR

                -- Make it fully visual and harmless
                creep.Parent = player     -- Mark player as “owner”
                creep.CollisionDamage = 0 -- Prevent damage
                creep.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                creep.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NONE
                creep:AddEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS)
            end
        end

        data.IsIdleGlitching = false
        data.IdleFrames = 0

        -------------------------------------------------
        -- B. DELIRIUM-STYLE IDLE GLITCH
        -------------------------------------------------
    else
        if player:GetFireDirection() == Direction.NO_DIRECTION then
            data.IdleFrames = data.IdleFrames + 1
        else
            data.IdleFrames = 0
        end

        if data.IdleFrames >= IDLE_THRESHOLD then
            data.IsIdleGlitching = true

            -- 1️⃣ Random color corruption
            local r = math.random(60, 140) / 100
            local g = math.random(60, 140) / 100
            local b = math.random(60, 140) / 100
            sprite.Color = Color(r, g, b, 1, 0, 0, 0)

            -- 2️⃣ Slight distortion
            sprite.Scale = Vector(
                1 + (math.random(-6, 6) / 100),
                1 + (math.random(-6, 6) / 100)
            )

            -- 3️⃣ Visual jitter
            sprite.Offset = Vector(
                math.random(-3, 3),
                math.random(-3, 3)
            )

            -- 4️⃣ Rare SAFE blink teleport
            if game:GetFrameCount() % 30 == 0 then
                SafeBlinkTeleport(player)
                sfx:Play(SoundEffect.SOUND_HELL_PORTAL1, 0.35, 0, false, 1.1)
            end

            -- 5️⃣ Rare animation desync
            if math.random(1, 30) == 1 then
                local currentFrame = sprite:GetFrame()
                sprite:SetFrame(math.random(0, currentFrame))
            end

            -- 6️⃣ Subtle glitch sound
            if game:GetFrameCount() % 40 == 0 then
                sfx:Play(SoundEffect.SOUND_STATIC, 0.2, 0, false, 1.2)
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPlayerUpdate)
