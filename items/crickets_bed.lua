GuppysCocoonMod = PBK

local GuppysCocoon = {
    ItemId = Isaac.GetItemIdByName("Cricket's Bed"),
    Damage = 40,
    FlyCountMin = 2,
    FlyCountMax = 4,
    SoundEffect = SoundEffect.SOUND_CHILD_ANGRY_ROAR,
    HolyMantleEffect = CollectibleType.COLLECTIBLE_HOLY_MANTLE
}

local sfx = SFXManager()

-- Aktivieren des Holy Mantle Effekts beim Benutzen
function GuppysCocoon:UseItem(_, _, player)
    local data = player:GetData()
    local effects = player:GetEffects()

    -- Gib temporären Holy Mantle Effekt (sichtbar im HUD)
    effects:AddCollectibleEffect(GuppysCocoon.HolyMantleEffect, false, 1)
    data.GuppysCocoonShieldActive = true -- Unsere interne Markierung

    return true
end

-- Überwachung, ob Holy Mantle "zerstört" wurde
function GuppysCocoon:OnPlayerUpdate(player)
    local data = player:GetData()
    local effects = player:GetEffects()

    if data.GuppysCocoonShieldActive then
        if not effects:HasCollectibleEffect(GuppysCocoon.HolyMantleEffect) then
            -- Holy Mantle wurde gebrochen
            data.GuppysCocoonShieldActive = false

            -- Fliegen spawnen
            local flyCount = math.random(GuppysCocoon.FlyCountMin, GuppysCocoon.FlyCountMax)
            for i = 1, flyCount do
                player:AddBlueFlies(1, player.Position, player)
            end

            -- Gegner in der Nähe Schaden zufügen
            for _, entity in ipairs(Isaac.GetRoomEntities()) do
                if entity:IsVulnerableEnemy() and entity.Position:Distance(player.Position) < 100 then
                    entity:TakeDamage(GuppysCocoon.Damage, 0, EntityRef(player), 0)
                end
            end

            -- Soundeffekt abspielen
            if not sfx:IsPlaying(GuppysCocoon.SoundEffect) then
                sfx:Play(GuppysCocoon.SoundEffect, 1.0, 0, false, 1.0)
            end
        end
    end
end

-- Falls Raum gewechselt wird, ohne dass Schild zerstört wurde
function GuppysCocoon:OnNewRoom()
    local player = Isaac.GetPlayer(0)
    local data = player:GetData()

    if data.GuppysCocoonShieldActive then
        data.GuppysCocoonShieldActive = false
    end
end

-- Callbacks
GuppysCocoonMod:AddCallback(ModCallbacks.MC_USE_ITEM, GuppysCocoon.UseItem, GuppysCocoon.ItemId)
GuppysCocoonMod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, GuppysCocoon.OnPlayerUpdate)
GuppysCocoonMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, GuppysCocoon.OnNewRoom)
