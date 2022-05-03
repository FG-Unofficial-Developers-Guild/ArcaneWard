--  	Author: Ryan Hagelstrom
--	  	Copyright © 2022
--	  	This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
--	  	https://creativecommons.org/licenses/by-sa/4.0/

local applyDamage = nil
local rest = nil

OOB_MSGTYPE_ARCANEWARD = "arcaneward"

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ARCANEWARD, handleArcaneWard)

	applyDamage = ActionDamage.applyDamage
	ActionDamage.applyDamage = customApplyDamage
	rest = CharManager.rest
	CharManager.rest = customRest
end

function onClose()
	applyDamage = ActionDamage.applyDamage
	CharManager.rest = rest
end


-- TODO: Figure out the spell that is being cast and get its type
-- actions id# group = Spells
-- actions id# school = Abjuration
-- if the spell is abjuration then increase the  ward by twice the spell level
-- if this is the first time cast today (active today flag false), then instead it has WIZLEVEL *2 + INTMOD
-- Only do all of this for PCs as Monsters start out their ward static
-- TODO: Need a DB entry for the Arcane Ward HP pool and also if it is currently active after long rest

function customRest(nodeActor, bLong)
	local rActor = ActorManager.resolveActor(nodeActor);
	if bLong and hasArcaneWard(rActor) then
		--TODO: -- Clear the arcane ward HP pool in the DB as well as the active today flag
	end
	rest(nodeActor, bLong)
end

function hasArcaneWard(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor)
	local nodeTraits = nodeActor.getChild("traitlist") or nodeActor.getChild("traits")
	if nodeTraits ~= nil then
		local aTraits = nodeTraits.getChildren()
		for _, nodeTrait in pairs(aTraits) do
			local sName = DB.getValue(nodeTrait, "name", "")
			if sName == "Arcane Ward" then
				--TODO: - parse NPC for the text "X hit points" and that is it's ward #
				return true
			end
		end
	end
	return false
end

-- TODO: Going to need a button or some sort of way to signal
-- to FG that an aburjation spell was cast for spells that don't have a FG
-- in game mechanic. ceremony, alarm etc.

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
		local rEffectSource = -- something
		arcaneWard(rSource, rEffectSource, bSecret, sDamage, nTotal)
	end
	if (hasArcaneWard(rTarget)) then
		arcaneWard(rSource, rTarget, bSecret, sDamage, nTotal)
	end
	return applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
end

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