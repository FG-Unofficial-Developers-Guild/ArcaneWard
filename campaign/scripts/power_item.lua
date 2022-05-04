function setFilter(bNewFilter)
    if super and super.setFilter then
	    return super.setFilter(bNewFilter)
	end
end

function getFilter()
    if super and super.getFilter then
		return super.getFilter()
	end
end

function onInit()
	local node = getDatabaseNode()
    local sSchool = DB.getValue(node, "school", "")
	local sGroup = DB.getValue(node, "group", "")
    local rActor = ActorManager.resolveActor(node.getParent().getParent())
	if sGroup == "Spells" and sSchool == "Abjuration" and ArcaneWard.hasArcaneWard(rActor) then
		setBackColor("Efccc8")
	end
	if super and super.onInit then
		return super.onInit()
	end
end

function onDisplayChanged()
    if super and super.onDisplayChanged then
		return super.onDisplayChanged()
	end
end

function createAction(sType)
    if super and super.createAction then
		return super.createAction(sType)
	end
end

function onMenuSelection(selection, subselection)
    if super and super.createAction then
		return super.onMenuSelection(selection, subselection)
	end
end

function toggleDetail()
    if super and super.toggleDetail then
		return super.toggleDetail()
	end
end

function getDescription(bShowFull)
    if super and super.getDescription then
		return super.getDescription(bShowFull)
	end
end

function usePower(bShowFull)
    local node = getDatabaseNode()
    local sSchool = DB.getValue(node, "school", "")
	local sGroup = DB.getValue(node, "group", "")
    local rActor = ActorManager.resolveActor(node.getParent().getParent())

    -- TODO: Deal with an upcast
    if sGroup == "Spells" and sSchool == "Abjuration" and ArcaneWard.hasArcaneWard(rActor) then
        local nLevel = DB.getValue(node, "level", 0)
		if Session.IsHost then
        	ArcaneWard.castAbjuration(node.getParent().getParent(), nLevel )
		else
			ArcaneWard.sendOOB(node.getParent().getParent(), nLevel)
		end

--		setBackColor("D6f1b5")

    end
    if super and super.usePower then
		return super.usePower(bShowFull)
	end

end