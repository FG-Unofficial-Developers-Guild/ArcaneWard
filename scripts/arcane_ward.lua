--  	Author: Ryan Hagelstrom
--	  	Copyright © 2022
--	  	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--	  	https://creativecommons.org/licenses/by-sa/4.0/

local applyDamage = nil
local rest = nil
local getPCPowerAction = nil

OOB_MSGTYPE_ARCANEWARD = "arcaneward"

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ARCANEWARD, handleArcaneWard)

	applyDamage = ActionDamage.applyDamage
	rest = CharManager.rest
	getPCPowerAction = PowerManager.getPCPowerAction

	ActionDamage.applyDamage = customApplyDamage
	CharManager.rest = customRest
--	PowerManager.getPCPowerAction = customGetPCPowerAction
end

function onClose()
	ActionDamage.applyDamage = applyDamage
	CharManager.rest = rest
	--PowerManager.getPCPowerAction = getPCPowerAction
end

function castAbjuration(nodeActor, nLevel)
	local nActive = DB.getValue(nodeActor, "arcaneward", 0)
	local nTotal

	if nActive == 1 then
		local nArcaneWardHP = DB.getValue(nodeActor, "hp.arcaneward", 0)
		nTotal = nArcaneWardHP + nLevel * 2
	else
		local nBonus = DB.getValue(nodeActor, "abilities.intelligence.bonus", 0)
--		local nWizLevel = DB.getValue(nodeActor, "abilities.intelligence.bonus", 0)
		local nWizLevel = 4
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
				--TODO: - parse NPC for the text "X hit points" and that is it's ward #
				return true
			end
		end
	end
	return false
end

function arcaneWard(rSource, rTarget, bSecret, sDamage, nTotal)
	--TODO: Function will subtract damage from the total that is absorbed by arcane ward
	-- and update the damage string. Any remaining will be pass on to applyDamage
end

function customApplyDamage (rSource, rTarget, bSecret, sDamage, nTotal)

	Debug.chat(sDamage)
	Debug.chat(nTotal)
	--TODO: If the target has an effect named Arcane Ward, the source of the effect
	-- will take the damage and the original target takes the rest
	local aArcaneWard = getEffectsByType(rTarget, "ARCANE WARD", {}, rSource)
	--Technically you could have two different wizards spend their reaction on this character
	for _,nodeEffect in pairs(aArcaneWard) do
	-- TODO: Get source. and pass him to arcaneWard
		local nodeSource = DB.getValue(nodeEffect,"source_name", "")
		local rEffectSource = ActorManager.resolveActor(nodeSource)
		if rEffectSource ~= nil then
			arcaneWard(rSource, rEffectSource, bSecret, sDamage, nTotal)
		end
	end
	if (hasArcaneWard(rTarget)) then
		arcaneWard(rSource, rTarget, bSecret, sDamage, nTotal)
	end
	return applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
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

-- function customEncodeActors(draginfo, rSource, aTargets)
-- 	if (draginfo and rSource and rSource.sConditions and rSource.sConditions ~= "") then
--         draginfo.setMetaData("sConditions",rSource.sConditions)
--     end
-- 	return	encodeActors(draginfo, rSource, aTargets)
-- end

-- setup up metadata for saves vs conditon when PC rolled from character sheet
-- Not needed- going a different route
-- function customGetPCPowerAction(nodeAction, sSubRoll)
-- 	local rAction, rActor = getPCPowerAction(nodeAction, sSubRoll)
-- 	--Debug.chat(rAction)
-- 	local sSchool = DB.getValue(nodeAction, "...school", "");
-- 	local sGroup = DB.getValue(nodeAction, "...group", "");
-- 	Debug.chat(sSchool ..  " " .. sGroup .. " " .. rAction.type)
-- 	if rActor ~= nil and rAction.save then
-- 		for _,v in pairs(DB.getChildren(nodeAction.getParent().getParent(), "")) do
-- 			local sGroup = DB.getValue(v, "group", "")
-- 			local sSchool = DB.getValue(v, "school", "")
-- 		end
-- 	end
-- 	return rAction, rActor
-- end

function sendOOB(nodeEffect,type, sEffect)
	local msgOOB = {}
-- TODO: Figure out what we want to send OOB
	-- msgOOB.type = type
	-- msgOOB.sNodeActor = nodeEffect.getParent().getParent().getPath()
	-- msgOOB.sNodeEffect = tostring(sDamage)
	-- if type == OOB_MSGTYPE_ARCANEWARD then
	-- 	msgOOB.sLabel = sEffect
	-- end
	Comm.deliverOOBMessage(msgOOB, "")
end

function handleArcaneWard(msgOOB)
-- TODO: Figure out what to handle
	-- if handlerCheck(msgOOB) then
	-- 	local nodeActor = DB.findNode(msgOOB.sNodeActor)
	-- 	local nodeEffect = DB.findNode(msgOOB.sDamage)
	-- 	EffectManager.deactivateEffect(nodeActor, nodeEffect)
	-- end
end