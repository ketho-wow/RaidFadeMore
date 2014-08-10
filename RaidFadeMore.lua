-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2011.11.06					---
--- Version: 0.3 [2014.08.10]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/raidfademore
--- WoWInterface	http://www.wowinterface.com/downloads/info23030-RaidFadeMore.html

local NAME = ...
local db

local UnitInRange = UnitInRange

local defaults = {
	db_version = .3,
	
	timeToFade = .5,
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

local FADEFRAMES = FADEFRAMES
local wakeUp = CreateFrame("Frame")

-- need a custom UIFrameFade function, since its secure and calls :Show (in combat)
local function FrameFade(frame, mode, timeToFade, startAlpha, endAlpha)
	local fadeInfo = {}
	fadeInfo.mode = mode
	fadeInfo.timeToFade = timeToFade
	fadeInfo.startAlpha = startAlpha
	fadeInfo.endAlpha = endAlpha
	frame:SetAlpha(fadeInfo.startAlpha)
	frame.fadeInfo = fadeInfo
	
	for _, v in pairs(FADEFRAMES) do
		if v == frame then
			return
		end
	end
	tinsert(FADEFRAMES, frame)
	
	-- dummy frame to poke the Blizzard frameFadeManager awake, since its not directly accessible
	UIFrameFadeIn(wakeUp, 0)
end

local f = CreateFrame("Frame")

function f:OnEvent(event, addon)
	if addon ~= NAME then return end
	
	if not RaidFadeMoreDB or defaults.db_version > RaidFadeMoreDB.db_version then
		RaidFadeMoreDB = CopyTable(defaults)
	end
	db = RaidFadeMoreDB
	
	local parent = "CompactUnitFrameProfilesGeneralOptionsFrame"
	local slider = CreateSlider(parent, "TOPLEFT", parent.."AutoActivateBG", "BOTTOMLEFT", 10, -30, "|cff71D5FF"..SPELL_FAILED_OUT_OF_RANGE.." Fade|r", "minAlpha")
	local sliderBg = CreateSlider(parent, "TOPLEFT", slider, "BOTTOMLEFT", 0, -40, "|cff71D5FF... "..BACKGROUND.." Fade|r", "minBgAlpha")
	
	-- FrameXML\CompactUnitFrame.lua
	hooksecurefunc("CompactUnitFrame_UpdateInRange", function(frame)
		if FADEFRAMES[frame] then return end
		
		local inRange, checkedRange = UnitInRange(frame.displayedUnit)
		if checkedRange and not inRange then
			if f[frame] == db.minAlpha then
				frame:SetAlpha(db.minAlpha)
				frame.background:SetAlpha(db.minBgAlpha)
			else
				FrameFade(frame, "OUT", db.timeToFade, db.maxAlpha, db.minAlpha)
				FrameFade(frame.background, "OUT", db.timeToFade, db.maxBgAlpha, db.minBgAlpha)
				f[frame] = db.minAlpha
			end
		else
			if f[frame] == db.maxAlpha then
				frame:SetAlpha(db.maxAlpha)
				frame.background:SetAlpha(db.maxBgAlpha)
			else
				FrameFade(frame, "IN", db.timeToFade, db.minAlpha, db.maxAlpha)
				FrameFade(frame.background, "IN", db.timeToFade, db.minBgAlpha, db.maxBgAlpha)
				f[frame] = db.maxAlpha
			end
		end
	end)
	self:UnregisterEvent(event)
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)
