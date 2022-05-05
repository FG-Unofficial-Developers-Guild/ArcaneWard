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

--TODO:
-- Button to cast abjuration spells
-- parse NPC for the text "X hit points" and that is it's ward #
-- CT and Char sheet boxes to display current AW HP
-- Upcast
-- AW Effect for reactions

OOB_MSGTYPE_ARCANEWARD = "arcaneward"

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ARCANEWARD, handleArcaneWard)

	applyDamage = ActionDamage.applyDamage
	messageDamage = ActionDamage.messageDamage
	rest = CharManager.rest

	ActionDamage.applyDamage = customApplyDamage
	ActionDamage.messageDamage = customMessageDamage
	CharManager.rest = customRest
end

function onClose()
	ActionDamage.applyDamage = applyDamage
	ActionDamage.messageDamage = messageDamage
	CharManager.rest = rest
end

function castAbjuration(nodeActor, nLevel)
	local nActive = DB.getValue(nodeActor, "arcaneward", 0)
	local nTotal

	if nActive == 1 then
		local nArcaneWardHP = DB.getValue(nodeActor, "hp.arcaneward", 0)
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
	DB.setValue(nodeActor, "hp.arcaneward", "number", nTotal)
end

function hasArcaneWard(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor)
	local nodeFeatures = nodeActor.getChild("featurelist")
	if nodeFeatures ~= nil then
		local aFeatures = nodeFeatures.getChildren()
		for _, nodeFeature in pairs(aFeatures) do
			local sName = DB.getValue(nodeFeature, "name", "")
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
	local nArcaneWardHP = DB.getValue(nodeTarget, "hp.arcaneward", 0)

	if nActive == 1 and nArcaneWardHP > 0 then
		local nTotalOrig = nTotal
		if nTotal >= nArcaneWardHP then
			nTotal = nTotal - nArcaneWardHP
			nArcaneWardHP = 0
		else
			nArcaneWardHP = nArcaneWardHP - nTotal
			nTotal = 0
		end
		DB.setValue(nodeTarget, "hp.arcaneward", "number", nArcaneWardHP)
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


function customApplyDamage (rSource, rTarget, bSecret, sDamage, nTotal)
	local ctEntries = CombatManager.getCombatantNodes()
	for _, nodeCT in pairs(ctEntries) do
		local rActor = ActorManager.resolveActor(nodeCT)
		if rActor ~= rSource and hasArcaneWard(rActor) then
			local aArcaneWard = EffectManager5E.getEffectsByType(rTarget, "ARCANEWARD", {}, rActor)
			if aArcaneWard ~= {} then
				--Technically you could have two different wizards spend their reaction on this character
				sDamage, nTotal = arcaneWard(rSource, rActor, bSecret, sDamage, nTotal)
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