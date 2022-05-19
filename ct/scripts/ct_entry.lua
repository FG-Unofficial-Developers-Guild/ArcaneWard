function onInit()
	super.onInit()
    onLinkChanged()
end

function onLinkChanged()
    super.onLinkChanged()
--	 If a PC, then set up the links to the char sheet
	local sClass, sRecord = link.getValue();
	if sClass == "charsheet" then
		linkPCFields();
		name.setLine(false);
	end
	onIDChanged();
end

function onIDChanged()
    super.onIDChanged()
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		arcaneward.setLink(nodeChar.createChild("hp.arcaneward", "number"));
    end
    super.linkPCFields()
end