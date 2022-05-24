local nLevel
function onInit()
    if super and super.onInit then
        super.onInit();
    end
    local node = window.getDatabaseNode()
    nLevel = DB.getValue(node, "level", 0)
    setCastToolTip(nLevel)
end

function setCastToolTip()
    local sToolTip
    local node = window.getDatabaseNode()
    local sDescription = DB.getValue(node, "description", "")
    local sSchool = DB.getValue(node, "school", "")
    local rActor = ActorManager.resolveActor(node.getParent().getParent())
    if sSchool == "Abjuration" and ArcaneWard.hasArcaneWard(rActor) then
        sToolTip = "Arcane Ward"
    else
        sToolTip = "Cast"
    end

    if sDescription:match("At Higher Levels") then
        sToolTip = sToolTip .. " as lvl " .. tostring(nLevel)
    end
    setTooltipText(sToolTip)
end

function onButtonPress()
    if super and super.onButtonPress() then
        super.onButtonPress()
    end
    local node = window.getDatabaseNode()
    --local nLevel = DB.getValue(node, "level", 0)
    local sGroup = DB.getValue(node, "group", "")
    local sSchool = DB.getValue(node, "school", "")
    local sType = DB.getValue(node, "type", "")
    local rActor = ActorManager.resolveActor(node.getParent().getParent())
    local sDescription = DB.getValue(node, "description", "");

    if sDescription:match("At Higher Levels") then
        getSpellSlots(node.getParent().getParent())
    end
    -- TODO: If not ritual
    expendSpellSlot(node.getParent().getParent(), nLevel)
    if sGroup == "Spells" and sSchool == "Abjuration" and ArcaneWard.hasArcaneWard(rActor) then
        ArcaneWard.castAbjuration(node.getParent().getParent(), nLevel)
    end
end
function onWheel(notches)
    local node = window.getDatabaseNode()
    local sDescription = DB.getValue(node, "description", "")
    if sDescription:match("At Higher Levels") then
        getSpellSlots(node.getParent().getParent())
    end

    if super and super.onWheel() then
        super.onWheel()
    end

end

function getSpellSlots(nodeChar)
    local aSpellSlots = {}
--    local aSlots = DB.getChildren(nodeChar,"powermeta")
    for i=1,9 do
        local nSlotsMax = DB.getValue(nodeChar, "powermeta.spellslots".. tostring(i) .. ".max", 0)
        local nSlotsUsed = DB.getValue(nodeChar, "powermeta.spellslots".. tostring(i) .. ".used", 0)
        if nSlotsUsed < nSlotsMax then
            aSpellSlots[i] =  nSlotsUsed
        end
    end
    Debug.chat(aSpellSlots)
    return aSpellsSlots
end

function expendSpellSlot(nodeChar, nLevel)
    local sSlotUsedString = "powermeta.spellslots".. tostring(nLevel) .. ".used"
    local nSlotsMax = DB.getValue(nodeChar, "powermeta.spellslots".. tostring(nLevel) .. ".max", 0)
    local nSlotsUsed = DB.getValue(nodeChar, sSlotUsedString, 0)

    if nSlotsUsed < nSlotsMax then
        DB.setValue(nodeChar, sSlotUsedString, "number", nSlotsUsed+1)
    end
end