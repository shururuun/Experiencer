------------------------------------------------------------
-- Experiencer by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------

local ADDON_NAME, Addon = ...;

local module = Addon:RegisterModule("artifact", {
	label       = "Artifact",
	order       = 3,
	savedvars   = {
		global = {
			ShowArtifactName = true,
			ShowRemaining = true,
			ShowUnspentPoints = true,
			ShowTotalArtifactPower = false,
		},
	},
});

module.levelUpRequiresAction = true;

function module:Initialize()
	self:RegisterEvent("ARTIFACT_XP_UPDATE");
	self:RegisterEvent("UNIT_INVENTORY_CHANGED");
end

function module:IsDisabled()
	-- If player doesn't have Legion on their account or hasn't completed first quest of artifact chain
	return GetExpansionLevel() < 6 or not module:HasCompletedArtifactIntro();
end

function module:Update(elapsed)
	
end

function module:CanLevelUp()
	if(not HasArtifactEquipped()) then return false end
	
	local _, _, _, _, totalXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo();
	local numPoints = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);
	return numPoints > 0;
end

function module:HasCompletedArtifactIntro()
	local quests = {
		40408, -- Paladin
		40579, -- Warrior
		40618, -- Hunter
		40636, -- Monk
		40646, -- Druid
		40684, -- Warlock
		40706, -- Priest
		40715, -- Death Knight
		40814, -- Demon Hunter
		40840, -- Rogue
		41085, -- Mage
		41335, -- Shaman
	};
	
	for _, questID in ipairs(quests) do
		if(IsQuestFlaggedCompleted(questID)) then return true end
	end
	
	return false;
end

function module:GetText()
	if(not HasArtifactEquipped()) then
		return "No artifact equipped";
	end
	
	local outputText = {};
	
	local itemID, altItemID, name, icon, totalXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo();
	local numPoints, artifactXP, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);
	
	local remaining         = xpForNextPoint - artifactXP;
	
	local progress          = artifactXP / (xpForNextPoint > 0 and xpForNextPoint or 1);
	local progressColor     = Addon:GetProgressColor(progress);
	
	if(self.db.global.ShowArtifactName) then
		tinsert(outputText,
			("|cffffecB3%s|r:"):format(name)
		);
	end
	
	if(self.db.global.ShowRemaining) then
		tinsert(outputText,
			("%s%s|r (%s%.1f|r%%)"):format(progressColor, BreakUpLargeNumbers(remaining), progressColor, 100 - progress * 100)
		);
	else
		tinsert(outputText,
			("%s%s|r / %s (%s%.1f|r%%)"):format(progressColor, BreakUpLargeNumbers(artifactXP), BreakUpLargeNumbers(xpForNextPoint), progressColor, progress * 100)
		);
	end
	
	if(self.db.global.ShowTotalArtifactPower) then
		tinsert(outputText,
			("%s |cffffdd00total artifact power|r"):format(BreakUpLargeNumbers(totalXP))
		);
	end
	
	if(self.db.global.ShowUnspentPoints and numPoints > 0) then
		tinsert(outputText,
			("|cff86ff33%d unspent point%s|r"):format(numPoints, numPoints == 1 and "" or "s")
		);
	end
	
	return table.concat(outputText, "  ");
end

function module:HasChatMessage()
	return HasArtifactEquipped(), "No artifact equipped.";
end

function module:GetChatMessage()
	local outputText = {};
	
	local itemID, altItemID, name, icon, totalXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo();
	local numPoints, artifactXP, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);
	
	local remaining = xpForNextPoint - artifactXP;
	local progress  = artifactXP / (xpForNextPoint > 0 and xpForNextPoint or 1);
	
	tinsert(outputText, ("%s is currently rank %s"):format(
		name,
		pointsSpent
	));
	
	if(pointsSpent > 0) then
		tinsert(outputText, ("at %s/%s power (%.1f%%) with %d to go"):format(
			BreakUpLargeNumbers(artifactXP),	
			BreakUpLargeNumbers(xpForNextPoint),
			progress * 100,
			remaining
		));
		
		if(numPoints > 0) then
			tinsert(outputText,
				("(%d unspent point%s)"):format(numPoints, numPoints == 1 and "" or "s")
			);
		end
	end
	
	return table.concat(outputText, " ");
end

function module:GetBarData()
	local data    = {};
	data.level    = 0;
	data.min  	  = 0;
	data.max  	  = 1;
	data.current  = 0;
	data.rested   = nil;
	data.visual   = nil;
	
	if(HasArtifactEquipped()) then
		local itemID, altItemID, name, icon, totalXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo();
		local numPoints, artifactXP, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP);
		
		data.level    = pointsSpent;
		data.max  	  = xpForNextPoint;
		data.current  = artifactXP;
	end
	
	return data;
end

function module:GetOptionsMenu()
	local menudata = {
		{
			text = "Artifact Options",
			isTitle = true,
			notCheckable = true,
		},
		{
			text = "Show remaining artifact power",
			func = function() self.db.global.ShowRemaining = true; module:RefreshText(); end,
			checked = function() return self.db.global.ShowRemaining == true; end,
		},
		{
			text = "Show current and max artifact power",
			func = function() self.db.global.ShowRemaining = false; module:RefreshText(); end,
			checked = function() return self.db.global.ShowRemaining == false; end,
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = "Show artifact name",
			func = function() self.db.global.ShowArtifactName = not self.db.global.ShowArtifactName; module:RefreshText(); end,
			checked = function() return self.db.global.ShowArtifactName; end,
			isNotRadio = true,
		},
		{
			text = "Show total artifact power",
			func = function() self.db.global.ShowTotalArtifactPower = not self.db.global.ShowTotalArtifactPower; module:RefreshText(); end,
			checked = function() return self.db.global.ShowTotalArtifactPower; end,
			isNotRadio = true,
		},
		{
			text = "Show unspent points",
			func = function() self.db.global.ShowUnspentPoints = not self.db.global.ShowUnspentPoints; module:RefreshText(); end,
			checked = function() return self.db.global.ShowUnspentPoints; end,
			isNotRadio = true,
		},
	};
	
	return menudata;
end

------------------------------------------

function module:ARTIFACT_XP_UPDATE()
	module:Refresh();
end

function module:UNIT_INVENTORY_CHANGED(event, unit)
	if(unit ~= "player") then return end
	if(self:IsDisabled()) then
		Addon:CheckDisabledStatus();
	else
		module:Refresh(true);
	end
end
