
function onInit()
    if super and super.onInit() then
        super.onInit()
    end
    if ArcaneWard.hasCA() then
        label_temp.setAnchor("right", "label_init", "left", "absolute", 195)
        label_wounds.setAnchor("right", "label_init", "left", "absolute", 75)
        label_hp.setAnchor("right", "label_init", "left", "absolute", 155)
        label_arcaneward.setAnchor("right", "label_init", "left", "absolute", 115)
    else
        label_hp.setAnchor("right", "label_init", "left", "absolute", 75)
        label_temp.setAnchor("right", "label_init", "left", "absolute", 115)
        label_wounds.setAnchor("right", "label_init", "left", "absolute", 155)
        label_arcaneward.setAnchor("right", "label_init", "left", "absolute", 195)
    end
end