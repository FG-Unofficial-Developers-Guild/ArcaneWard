--function onFirstLayout()

function onInit()
    if super and super.onInit() then
        super.onInit()
    end
    if ArcaneWard.hasCA() then
        wounds.setAnchor("right", "healthbase", "left", "absolute", 30)
        hptotal.setAnchor("right", "healthbase", "left", "absolute", 70)
        hptemp.setAnchor("right", "healthbase", "left", "absolute", 110)
        arcaneward.setAnchor("right", "healthbase", "left", "absolute", 150)
    end
end

function updateHealthDisplay()
    if super and super.updateHealthDisplay() then
        super.updateHealthDisplay()
    end
	local sOption;
	if friendfoe.getStringValue() == "friend" then
		sOption = OptionsManager.getOption("SHPC");
	else
		sOption = OptionsManager.getOption("SHNPC");
	end

	if sOption == "detailed" then
        arcaneward.setVisible(true);
	elseif sOption == "status" then
        arcaneward.setVisible(false);
	else
        arcaneward.setVisible(false);
	end
end