local HerzbrandMod = RegisterMod("Heartburn", 1)
local game = Game()
local rng = RNG()
local SFX = SFXManager()
local ItemId = Isaac.GetItemIdByName("Heartburn")

-- Custom Soundeffekt
local CONVERT_SOUND = SoundEffect.SOUND_DEVIL_CARD

function HerzbrandMod:UseHerzbrand(_, _, player)
    local room = game:GetRoom()
    local entities = Isaac.GetRoomEntities()
    local redHearts = {}

    -- Sammle alle roten Herzen im Raum, die sich nicht als Shop-Item kennzeichnen
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_HEART then
            local subtype = entity.SubType
            local entityData = entity:GetData()
            local isInShop = entityData and entityData.IsInShop

            -- Verarbeite nur Herzen, die nicht im Shop sind
            if not isInShop then
                if subtype == HeartSubType.HEART_FULL or
                   subtype == HeartSubType.HEART_HALF or
                   subtype == HeartSubType.HEART_DOUBLEPACK or
                   subtype == HeartSubType.HEART_SCARED or
                   subtype == HeartSubType.HEART_BLENDED then
                    table.insert(redHearts, entity)
                end
            end
        end
    end

    local numRedHearts = #redHearts

    -- Behandlung für den Fall eines einzelnen roten Herzens
    if numRedHearts == 1 then
        local entity = redHearts[1]
        local pos = entity.Position
        entity:Remove()
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, pos, Vector(0,0), nil)
        SFX:Play(SoundEffect.SOUND_LUCKYPICKUP, 1.0, 0, false, 1.0)
        return true
    end

    -- Berechnung der Anzahl der Herzen, die konvertiert und verbrannt werden sollen
    local numToConvert = math.floor(numRedHearts * 0.6)
    local numToBurn = numRedHearts - numToConvert

    -- Mische die Liste der roten Herzen zufällig, um eine faire Auswahl zu treffen
    for i = numRedHearts, 2, -1 do
        local j = rng:RandomInt(1, i)
        redHearts[i], redHearts[j] = redHearts[j], redHearts[i]
    end

    -- Konvertiere die ersten numToConvert Herzen in schwarze Herzen
    for i = 1, numToConvert do
        local entity = redHearts[i]
        local pos = entity.Position
        entity:Remove()
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, pos, Vector(0,0), nil)
        SFX:Play(SoundEffect.SOUND_LUCKYPICKUP, 1.0, 0, false, 1.0)
    end

    -- Erzeuge den HOT_BOMB_FIRE Effekt anstelle von Fireplaces
    for i = numToConvert + 1, numRedHearts do
        local entity = redHearts[i]
        local pos = entity.Position
        entity:Remove()
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.HOT_BOMB_FIRE, 0, pos, Vector(0, 0), nil)
    end

    return true
end

HerzbrandMod:AddCallback(ModCallbacks.MC_USE_ITEM, HerzbrandMod.UseHerzbrand, ItemId)