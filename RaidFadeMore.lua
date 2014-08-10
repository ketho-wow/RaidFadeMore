-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2011.11.06					---
--- Version: 0.2 [2014.08.10]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/raidfademore
--- WoWInterface	x

local NAME = ...
local db

local defaults = {
	db_version = .1,
	
	minAlpha = .2,
	maxAlpha = 1,
	
	minBgAlpha = .5,
	maxBgAlpha = 1,
}

local function CreateSlider(parent, point, relativeTo, relativePoint, x, y, label, option)
	-- slider
	local s = CreateFrame("Slider", nil, _G[parent], "CompactUnitFrameProfilesSliderTemplate")
	s:SetPoint(point, relativeTo, relativePoint, x, y)
	s.label:SetText(label)
	s.minLabel:SetText(0); s.maxLabel:SetText(1)
	s:SetValueStep(5); s:SetMinMaxValues(0, 100)
	s:SetObeyStepOnDrag(true)
	s:SetValue(db[option]*100)
	
	s:SetScript("OnValueChanged", function(self, value)
		local v = value/100
		db[option] = v
		s.curLabel:SetText(v)
	end)
	
	-- fontstring
	s.curLabel = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	s.curLabel:SetPoint("TOP", s, "BOTTOM")
	s.curLabel:SetText(db[option])
	
	return s
end

local f = CreateFrame("Frame")

function f:OnEvent(event, addon)
	if addon ~= NAME then return end
	
	RaidFadeMoreDB = RaidFadeMoreDB or CopyTable(defaults)
	db = RaidFadeMoreDB
	
	local parent = "CompactUnitFrameProfilesGeneralOptionsFrame"
	local slider = CreateSlider(parent, "TOPLEFT", parent.."AutoActivateBG", "BOTTOMLEFT", 10, -30, "|cff71D5FF"..SPELL_FAILED_OUT_OF_RANGE.." Fade|r", "minAlpha")
	local sliderBg = CreateSlider(parent, "TOPLEFT", slider, "BOTTOMLEFT", 0, -40, "|cff71D5FF... "..BACKGROUND.." Fade|r", "minBgAlpha")
	
	-- FrameXML\CompactUnitFrame.lua
	hooksecurefunc("CompactUnitFrame_UpdateInRange", function(frame)
		local inRange, checkedRange = UnitInRange(frame.displayedUnit)
		if checkedRange and not inRange then
			frame:SetAlpha(db.minAlpha)
			frame.background:SetAlpha(db.minBgAlpha)
		else
			frame:SetAlpha(db.maxAlpha)
			frame.background:SetAlpha(db.maxBgAlpha)
		end
	end)
	
	self:UnregisterEvent(event)
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)
