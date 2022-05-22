function onInit()
    if super and super.onInit then
        super.onInit();
    end

end


function onButtonPress()
    if super and super.onButtonPress() then
        super.onButtonPress()
    end
    local node = window.getDatabaseNode()
    local nLevel = DB.getValue(node, "level", 0)
    local sGroup = DB.getValue(node, "group", "")
    local sSchool = DB.getValue(node, "school", "")
    local sType = DB.getValue(node, "type", "")
    local rActor = ActorManager.resolveActor(node.getParent().getParent())
    local sDescription = DB.getValue(node, "description", "");
    if Input.isShiftPressed() and sDescription:match("At Higher Levels") then
        Debug.chat("upcast")
   --     nLevel = some level
    end
    if sGroup == "Spells" and sSchool == "Abjuration" and ArcaneWard.hasArcaneWard(rActor) then
        ArcaneWard.castAbjuration(node.getParent().getParent(), nLevel)
    end
--    DB.setValue(nodeChar, "powermeta.spellslots1.max", "number", DB.getValue(nodeChar, "powermeta.spellslots1.max", 0) + 1);
end