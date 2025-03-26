local mod = RegisterMod("MyMod", 1)

-- Require other Lua files and capture the returned item ID
local PURGATORY_FLAME = require("purgatory_flame")

require("bee_buster")
require("chirping_alarm")
require("damage_potion")
require("loaded_die")
require("optic_bomb")
require("paper_shredder")
require("pollen")
require("pyro_mantle")
require("smouldering_dice")
require("the_button")
require("duality_mirror")
require("Pseudotheism")
require("rule_of_power")

-- Character: Gabriel
local gabrielType = Isaac.GetPlayerTypeByName("Gabriel", false)
local hairCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_hair.anm2")
local stolesCostume = Isaac.GetCostumeIdByPath("gfx/characters/gabriel_stoles.anm2")

function mod:OnGabrielInit(player)
    if player:GetPlayerType() == gabrielType then
        -- Add costumes
        player:AddNullCostume(hairCostume)
        player:AddNullCostume(stolesCostume)
        
        -- Give "Purgatory Flame" as a starting pocket item
        player:AddCollectible(PURGATORY_FLAME, 0, false)
        player:FullCharge()
        
        -- Remove "Purgatory Flame" from the item pool so it can't be found normally
        Game():GetItemPool():RemoveCollectible(PURGATORY_FLAME)
    end
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OnGabrielInit)

function mod:GiveCostumesOnInit(player)
    if player:GetPlayerType() ~= gabrielType then return end
    player:AddNullCostume(hairCostume)
    player:AddNullCostume(stolesCostume)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.GiveCostumesOnInit)


-- Character: Tainted Gabriel
local taintedGabrielType = Isaac.GetPlayerTypeByName("Gabriel", true)
local holyOutburstID = Isaac.GetItemIdByName("Holy Outburst")

function mod:TaintedGabrielInit(player)
    if player:GetPlayerType() ~= taintedGabrielType then return end
    player:SetPocketActiveItem(holyOutburstID, ActiveSlot.SLOT_POCKET, true)
    Game():GetItemPool():RemoveCollectible(holyOutburstID)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.TaintedGabrielInit)

function mod:HolyOutburstUse(_, _, player)
    local creep = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_HOLYWATER, 0, player.Position, Vector.Zero, player):ToEffect()
    
    if creep then  -- Check if creep is not nil
        creep.Scale = 2
        creep:Update()
    end
    
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.HolyOutburstUse, holyOutburstID)