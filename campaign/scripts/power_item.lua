
-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super and super.onInit then
        super.onInit();
    end

    onDisplayChanged();
    windowlist.onChildWindowAdded(self);
end

function onDisplayChanged()
    if super and super.onDisplayChanged then
        super.onDisplayChanged();
    end
    local node = getDatabaseNode()

    local sGroup = DB.getValue(node, "group", "")
    local sSchool = DB.getValue(node, "school", "")
    local nLevel = DB.getValue(node, "level", 0)
    local rActor = ActorManager.resolveActor(node.getParent().getParent())

    local sDisplayMode = DB.getValue(getDatabaseNode(), "...powerdisplaymode", "");
    if sDisplayMode == "summary" then
        header.subwindow.button_abjuration.setVisible(false);
        header.subwindow.arcaneward_text_label.setVisible(false);
    elseif sDisplayMode == "action" and sGroup == "Spells" then
        if sSchool == "Abjuration" and ArcaneWard.hasArcaneWard(rActor) then
            header.subwindow.arcaneward_text_label.setVisible(true);
            header.subwindow.button_abjuration.setVisible(true);
            header.subwindow.button_abjuration.setIcons("button_arcaneward","button_arcaneward_pressed")
            header.subwindow.button_abjuration.setTooltipText("Arcane Ward")
        elseif nLevel > 0 then
            header.subwindow.button_abjuration.setIcons("button_cast_spell", "button_cast_spell_done")
            header.subwindow.button_abjuration.setTooltipText("Cast")
        else
            header.subwindow.button_abjuration.setVisible(false);
            header.subwindow.arcaneward_text_label.setVisible(false);
        end
    --    if OptionsManager.isOption("SAIC", "on") then
  --          header.subwindow.components_text_label.setVisible(true);
 --       end
    else
        header.subwindow.button_abjuration.setVisible(false);
        header.subwindow.arcaneward_text_label.setVisible(false);
    end
end