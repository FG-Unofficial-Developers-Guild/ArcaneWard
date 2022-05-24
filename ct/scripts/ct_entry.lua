function onInit()
	if super and super.onInit() then
		super.onInit()
	end
    onLinkChanged()
end

function onLinkChanged()
	if super and super.onLinkChanged() then
    	super.onLinkChanged()
	end

--	 If a PC, then set up the links to the char sheet
	local sClass, sRecord = link.getValue();
	if sClass == "charsheet" then
		linkPCFields();
		name.setLine(false);
	end
	onIDChanged();
end

function onIDChanged()
	if super and super.onIDChanged() then
		super.onIDChanged()
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		arcaneward.setLink(nodeChar.createChild("hp.arcaneward", "number"));
    else
--		arcaneward.setLink(nodeChar.createChild("arcanewardhp", "number"));
	end
	if super and super.linkPCFields() then
    	super.linkPCFields()
	end
end