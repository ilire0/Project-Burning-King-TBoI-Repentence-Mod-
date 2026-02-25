local mod = PBK
-- Pyro Mantle
local ITEM_ID = Isaac.GetItemIdByName("Pyro Mantle")

local AURA_RADIUS_BASE = 150
local AURA_RADIUS_LUCK = 10
local MAX_RADIUS = 600

local auraEntity = nil

-- Berechnet eine rote Aura, ähnlich dem Holy Mantle-Effekt
local function getAuraColor()
    return Color(1, 0, 0, 0.6)
end

function mod:updateAura()
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(ITEM_ID) then
        local luck = player.Luck
        local radius = math.min(AURA_RADIUS_BASE + (luck * AURA_RADIUS_LUCK), MAX_RADIUS)

        -- Falls die Aura nicht existiert, erstelle sie neu
        if not auraEntity or not auraEntity:Exists() then
            auraEntity = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RED_CANDLE_FLAME, 0, player.Position,
                Vector(0, 0), player)
            auraEntity:GetSprite().Scale = Vector(radius / 100, radius / 100)
        end

        -- Aktualisiert Position, Skalierung und Farbe der Aura
        auraEntity.Position = player.Position
        auraEntity:GetSprite().Scale = Vector(radius / 100, radius / 100)
        auraEntity.Color = getAuraColor()
    end
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.updateAura)

function mod:onProjectileUpdate(projectile)
    local player = Isaac.GetPlayer(0)
    if player:HasCollectible(ITEM_ID) then
        local luck = player.Luck
        local radius = math.min(AURA_RADIUS_BASE + (luck * AURA_RADIUS_LUCK), MAX_RADIUS)

        if player.Position:Distance(projectile.Position) <= radius then
            local baseChance = 0.05
            local maxChance = 0.5
            local chance = math.min(baseChance + (luck * 0.05), maxChance)

            if math.random() < chance then
                local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.EMBER_PARTICLE, 0, projectile
                .Position, Vector(0, 0), nil)
                effect:GetSprite().Color = Color(1, 0.5, 0, 1)

                local explosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.BOMB_EXPLOSION, 0,
                    projectile.Position, Vector(0, 0), nil)
                explosion.SpriteScale = Vector(0.5, 0.5)
                explosion:GetSprite().Color = Color(1, 0.7, 0, 1)

                projectile:Remove()
            end
        end
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, mod.onProjectileUpdate)

print("My Mod loaded successfully!")
