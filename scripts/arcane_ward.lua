--  	Author: Ryan Hagelstrom
--	  	Copyright © 2022
--	  	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--	  	https://creativecommons.org/licenses/by-sa/4.0/

-- Sage Advice
-- https://dnd.wizards.com/articles/features/sageadvice_july2015
-- How does Arcane Ward interact with temporary hit points and damage resistance that an abjurer might have?
-- An Arcane Ward is not an extension of the wizard who creates it. It is a magical effect with its own hit points.
-- Any temporary hit points, immunities, or resistances that the wizard has don’t apply to the ward.

-- The ward takes damage first. Any leftover damage is taken by the wizard and goes through the following game elements in order:
--  (1) any relevant damage immunity,
--  (2) any relevant damage resistance,
--  (3) any temporary hit points, and
--  (4) real hit points.

local applyDamage = nil
local messageDamage = nil
local rest = nil
local addNPCtoCT = nil
--TODO:
-- Button to cast abjuration spells
-- parse NPC for the text "X hit points" and that is it's ward #
-- CT and Char sheet boxes to display current AW HP
-- Upcast

OOB_MSGTYPE_ARCANEWARD = "arcaneward"

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ARCANEWARD, handleArcaneWard)

	applyDamage = ActionDamage.applyDamage
	messageDamage = ActionDamage.messageDamage
	rest = CharManager.rest
	addNPCtoCT= CombatManager.addNPC

	ActionDamage.applyDamage = customApplyDamage
	ActionDamage.messageDamage = customMessageDamage
	CharManager.rest = customRest
	CombatManager.addNPC = customAddNPCtoCT

end

function onClose()
	ActionDamage.applyDamage = applyDamage
	ActionDamage.messageDamage = messageDamage
	CharManager.rest = rest
	CombatManager.addNPC = addNPCtoCT
end

function castAbjuration(nodeActor, nLevel)
	local nActive = DB.getValue(nodeActor, "arcaneward", 0)
	local sDBAWHP = getDBString(nodeActor)
	local nTotal

	if nActive == 1 then
		local nArcaneWardHP = DB.getValue(nodeActor, sDBAWHP, 0)
		nTotal = nArcaneWardHP + nLevel * 2
	else
		local nBonus = DB.getValue(nodeActor, "abilities.intelligence.bonus", 0)
		for _,nodeClass in pairs(DB.getChildren(nodeActor, "classes")) do
			local sClassName = StringManager.trim(DB.getValue(nodeClass, "name", "")):lower()
			if sClassName == "wizard" or sClassName == "runewalker" then
				nWizLevel = DB.getValue(nodeClass, "level", 0)
				break
			end
		end
		nTotal = nWizLevel * 2  + nBonus
		DB.setValue(nodeActor, "arcaneward", "number", 1)
	end
	DB.setValue(nodeActor, sDBAWHP, "number", nTotal)
end

function hasArcaneWard(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor)
	local nodeFeatures = nodeActor.getChild("featurelist")
	--PCs
	if nodeFeatures ~= nil and (rActor.sType == "pc" or rActor.sType == "charsheet") then
		local aFeatures = nodeFeatures.getChildren()
		for _, nodeFeature in pairs(aFeatures) do
			local sName = DB.getValue(nodeFeature, "name", "")
			if sName:upper() == "ARCANE WARD" then
				return true
			end
		end
	end
	--NPCs
	local nodeTraits = nodeActor.getChild("traits")
	if nodeTraits ~= nil and rActor.sType == "npc" then
		local aTraits = nodeTraits.getChildren()
		for _, nodeTrait in pairs(aTraits) do
			local sName = DB.getValue(nodeTrait, "name", "")
			if sName:upper() == "ARCANE WARD" then
				return true
			end
		end
	end
	return false
end

function arcaneWard(rSource, rTarget, bSecret, sDamage, nTotal)
	local nodeTarget = ActorManager.getCreatureNode(rTarget)
	local nActive = DB.getValue(nodeTarget, "arcaneward", 0)
	local sDBAWHP = getDBString(nodeTarget)
--	Debug.chat("ArcaneWard: " .. sDBAWHP)
	local nArcaneWardHP = DB.getValue(nodeTarget, sDBAWHP, 0)

	if nActive == 1 and nArcaneWardHP > 0 then
		local nTotalOrig = nTotal
		if nTotal >= nArcaneWardHP then
			nTotal = nTotal - nArcaneWardHP
			nArcaneWardHP = 0
		else
			nArcaneWardHP = nArcaneWardHP - nTotal
			nTotal = 0
		end
		DB.setValue(nodeTarget, sDBAWHP, "number", nArcaneWardHP)
		sDamage = removeAbsorbed(sDamage, nTotalOrig -  nTotal)
		sDamage =  "[ARCANE WARD: " .. tostring(nTotalOrig - nTotal) .. "] " .. sDamage
	end
	return sDamage, nTotal
end

--this is kind of a mess but I'm done with string manip for the day
--fix this up nice some other time (yeah right)
function removeAbsorbed(sDamage, nAbsorbed)
	local result = {}
	local regex = ("([^%s]+)"):format("[TY")
	for each in sDamage:gmatch(regex) do
	   table.insert(result, each)
	end
	local sNewDamage = ""
	for _, sClause in pairs(result) do
		if sClause:match("PE:") then
			sClause = "[TY" .. sClause
			local nClauseDamage = tonumber(sClause:match("=%d+%)"):match("%d+"))
			if nAbsorbed >= nClauseDamage then
				nAbsorbed = nAbsorbed - nClauseDamage
			else
				nClauseDamage = nClauseDamage - nAbsorbed
				nAbsorbed = 0
				sClause = sClause:gsub("=%d+%)", "=" .. tostring(nClauseDamage) .. ")")
				sNewDamage = sNewDamage .. sClause
			end
		else
			sNewDamage = sNewDamage .. sClause -- not damage clause so it passes though
		end
	end
	return sNewDamage
end

function getDBString(node)
	local rActor = ActorManager.resolveActor(node)
	if ActorManager.isPC(rActor) then
		return "hp.arcaneward"
	else
		return "arcanewardhp"
	end
end


function customApplyDamage (rSource, rTarget, bSecret, sDamage, nTotal)
	-- Get the effects on source, determine. is arcane ward. determine source
	local aArcaneWardEffects = getEffectsByType(rTarget, "ARCANEWARD")
	if next(aArcaneWardEffects) then
		local ctEntries = CombatManager.getCombatantNodes()
		for _, nodeCT in pairs(ctEntries) do
			local rActor = ActorManager.resolveActor(nodeCT)
			if hasArcaneWard(rActor) then
				for _, rEffect in pairs(aArcaneWardEffects) do
					if rEffect.source_name == rActor.sCTNode then
						sDamage, nTotal = arcaneWard(rSource, rActor, bSecret, sDamage, nTotal)
					end
				end
			end
		end
	end
	if (hasArcaneWard(rTarget)) then
		sDamage, nTotal = arcaneWard(rSource, rTarget, bSecret, sDamage, nTotal)
	end
	return applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
end

function customMessageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
	--TODO: Think we need to loop here incase of multiple arcane wards
	local sArcaneWard = sDamageDesc:match("%[ARCANE WARD:%s*%d*]")
	if sArcaneWard ~= nil then
		sExtraResult = "ABSORB " .. sArcaneWard .. sExtraResult
	end
	return messageDamage(rSource, rTarget, bSecret, sDamageType, sDamageDesc, sTotal, sExtraResult)
end

function customRest(nodeActor, bLong)
	local rActor = ActorManager.resolveActor(nodeActor)
	if bLong and hasArcaneWard(rActor) then
		local nActive = DB.getValue(nodeActor, "arcaneward", 0)
		if nActive == 1 then
			DB.setValue(nodeActor, "arcaneward", "number", 0)
			DB.setValue(nodeActor, "hp.arcaneward", "number", 0)
		end
	end
	rest(nodeActor, bLong)
end


function customAddNPCtoCT(sClass, nodeNPC, sName)
	local nodeCTEntry  = addNPCtoCT(sClass, nodeNPC, sName)
	local nodeFeatures = nodeCTEntry.getChild("traits")
	local aFeatures = nodeFeatures.getChildren()
	for _, nodeFeature in pairs(aFeatures) do
		local sFeatureName = DB.getValue(nodeFeature, "name", "")
		if sFeatureName:upper() == "ARCANE WARD" then
			local sDesc =  DB.getValue(nodeFeature, "desc", "")
			local aWords = StringManager.parseWords(sDesc)
			local nArcaneWard = 0
			local i = 1
			while aWords[i] do
				if StringManager.isWord(aWords[i], "hit") and StringManager.isWord(aWords[i+1], "points") then
					nArcaneWard = tonumber(aWords[i-1])
					DB.setValue(nodeCTEntry, "arcaneward", "number", 1)
					DB.setValue(nodeCTEntry, "arcanewardhp", "number", nArcaneWard)
					break
				end
				i = i + 1
			end
		end
	end
	return nodeCTEntry
end

--Modified from coreRPG to also return the CTNode whom applied the effect
--5E version is too bloated for what we need
function getEffectsByType(rActor, sEffectCompType, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local tResults = {};
	local tEffectCompParams = {}
	tEffectCompParams[sEffectCompType] = {}
	-- Iterate through effects
	for _,v in pairs(ActorManager.getEffects(rActor)) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		local bActive =
				(tEffectCompParams.bIgnoreExpire and (nActive == 1)) or
				(not tEffectCompParams.bIgnoreExpire and (nActive ~= 0));

		if bActive then
			-- If effect type we are looking for supports targets, then check targeting
			local bTargetMatch = false;
			if tEffectCompParams.bIgnoreTarget then
				bTargetMatch = true;
			else
				local bTargeted = EffectManager.isTargetedEffect(v);
				if bTargeted then
					bTargetMatch = EffectManager.isEffectTarget(v, rFilterActor);
				else
					bTargetMatch = not bTargetedOnly;
				end
			end

			if bTargetMatch then
				local sLabel = DB.getValue(v, "label", "");
				local aEffectComps = EffectManager.parseEffect(sLabel);
				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp,sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager.parseEffectCompSimple(sEffectComp);
					if rEffectComp.type:upper() == sEffectCompType or rEffectComp.original:upper() == sEffectCompType then
						nMatch = kEffectComp;
						if nActive == 1 then
							rEffectComp.source_name = DB.getValue(v, "source_name", "");
							table.insert(tResults, rEffectComp);
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if (nMatch > 0) and not tEffectCompParams.bIgnoreExpire then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						local sApply = DB.getValue(v, "apply", "");
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP

	-- RESULTS
	return tResults;
end
function sendOOB(nodeActor,nLevel)
	local msgOOB = {}
	msgOOB.sNodeActor = nodeActor
	msgOOB.sNodeEffect = tostring(nLevel)
	msgOOB.type = OOB_MSGTYPE_ARCANEWARD
	Comm.deliverOOBMessage(msgOOB, "")
end

function handleArcaneWard(msgOOB)
	local nodeActor = DB.findNode(msgOOB.sNodeActor)
	if not nodeActor then
		ChatManager.SystemMessage(Interface.getString("ct_error_aw_missingactor") .. " (" .. msgOOB.sNodeActor .. ")")
		return false
	end
	local sLevel = DB.findNode(msgOOB.sLevel)
	if not sLevel then
		ChatManager.SystemMessage(Interface.getString("ct_error_aw_missinglevel") .. " (" .. msgOOB.sLevel .. ")")
		return false
	end
	local nLevel = tonumber(sLevel)
	castAbjuration(nodeActor, nLevel)
end