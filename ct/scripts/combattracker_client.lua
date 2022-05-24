--function onFirstLayout()

function onInit()
    OptionsManager.registerCallback("SHPC", updateHealthDisplayAW);
    OptionsManager.registerCallback("SHNPC", updateHealthDisplayAW);

    if super and super.onInit() then
        super.onInit()
    end

    if ArcaneWard.hasCA() then
        label_init.setAnchor("right", "rightanchor", "left", "absolute", -170)
        label_wounds.setAnchor("right", "rightanchor", "left", "absolute", -130)
        label_hp.setAnchor("right", "rightanchor", "left", "absolute", -90)
        label_temp.setAnchor("right", "rightanchor", "left", "absolute", -50)
        label_arcaneward.setAnchor("right", "rightanchor", "left", "absolute", -10)
    end
end

function onClose()
    if super and super.onClose() then
        super.onClose();
    end
    OptionsManager.unregisterCallback("SHPC", updateHealthDisplayAW);
    OptionsManager.unregisterCallback("SHNPC", updateHealthDisplayAW);
end

function updateHealthDisplayAW()
    local sOptSHPC = OptionsManager.getOption("SHPC");
    local sOptSHNPC = OptionsManager.getOption("SHNPC");
    local bShowDetail = (sOptSHPC == "detailed") or (sOptSHNPC == "detailed");
    label_arcaneward.setVisible(bShowDetail);
end