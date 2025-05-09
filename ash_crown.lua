-- Define the item ID
local AshCrown = Isaac.GetItemIdByName("Ash Crown")

-- Define a mod table
local myMod = RegisterMod("Ash Crown Mod", 1)

-- Variables to track affected enemies and frame count
local affectedEnemies = {}
local frameCount = 0

-- Function to check if the player has no filled red hearts and at least half a soul or black heart
local function HasNoFilledRedAndSoulOrBlackHearts(player)
    return (player:GetHearts() == 0 or player:GetMaxHearts() == 0) and player:GetSoulHearts() > 0
end

-- Function to handle ash trail effects
local function OnGameUpdate()
    local player = Isaac.GetPlayer(0)

    if player and player:HasCollectible(AshCrown) and HasNoFilledRedAndSoulOrBlackHearts(player) then
        -- Increment frame count
        frameCount = frameCount + 1

        -- Spawn effect every 4th frame
        if frameCount % 4 == 0 then
            -- Find all tears in the room
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                if entity.Type == EntityType.ENTITY_TEAR then
                    local tear = entity:ToTear()
                    -- Check if the tear belongs to the player
                    if tear and tear.Position and tear.SpawnerType == EntityType.ENTITY_PLAYER then
                        -- Spawn the Black Powder effect
                        local blackPowderEffect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACKPOWDER, 0, tear.Position, Vector.Zero, player):ToEffect()
                        if blackPowderEffect then
                            blackPowderEffect.SpriteScale = Vector(0.7, 0.7) -- Make it larger
                            blackPowderEffect:SetTimeout(120) -- Set the effect to last for 120 frames (2 seconds)
                            blackPowderEffect:Update() -- Update to apply changes immediately
                        end
                    end
                end
            end
        end
    end

    -- Handle ash trail effects on enemies
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsVulnerableEnemy() then
            -- Check if the enemy is on any black powder effect
            local blackPowderEffects = Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACKPOWDER, -1, false, false)
            for _, effect in ipairs(blackPowderEffects) do
                if entity.Position:Distance(effect.Position) < 40 then
                    -- Apply slowing effect for 180 frames (3 seconds)
                    entity:AddSlowing(EntityRef(effect), 180, 0.5, Color(0.5, 0.5, 0.5, 1, 0, 0, 0))
                    -- Apply burning effect for 180 frames (3 seconds)
                    entity:AddBurn(EntityRef(effect), 180, 1.0) -- Burn for 180 frames with 1.0 damage per tick
                    -- Add enemy to affected list if not already present
                    if not affectedEnemies[entity.InitSeed] then
                        table.insert(affectedEnemies, entity)
                        affectedEnemies[entity.InitSeed] = true
                    end
                end
            end
        end
    end

    -- Check for enemies that die in the effect
    for i = #affectedEnemies, 1, -1 do
        local enemy = affectedEnemies[i]
        if not enemy:Exists() or enemy:IsDead() then
            -- Create a smaller explosion at the enemy's position
            Game():BombExplosionEffects(enemy.Position, 20, TearFlags.TEAR_NORMAL, Color.Default, player, 0.5, true, false)
            table.remove(affectedEnemies, i)
        end
    end
end

-- Register the callback
myMod:AddCallback(ModCallbacks.MC_POST_UPDATE, OnGameUpdate)