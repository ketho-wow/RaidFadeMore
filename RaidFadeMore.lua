-------------------------------------------
--- Author: Ketho (EU-Boulderfist)		---
--- License: Public Domain				---
--- Created: 2014.08.10					---
--- Version: 0.5 [2014.08.10]			---
-------------------------------------------
--- Curse			http://www.curse.com/addons/wow/raidfademore
--- WoWInterface	http://www.wowinterface.com/downloads/info23030-RaidFadeMore.html

local NAME = ...
local db

local list = {}
local isSliding

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
	
	-- prevent fading transitions while moving the slider
	if option == "minAlpha" then
		s:SetScript("OnMouseDown", function(self, button)
			isSliding = true
		end)
		
		s:SetScript("OnMouseUp", function(self, button)
			isSliding = false
			
			-- prevent fading transitions after moving the slider
			for frame in pairs(list) do
				if frame.displayedUnit then -- list is not up to date anymore after leaving a raid
					local inRange, checkedRange = UnitInRange(frame.displayedUnit)
					list[frame] = (checkedRange and not inRange) and db[option] or db.maxAlpha
				end
			end
		end)
	end
	
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
	frame:SetAlpha(startAlpha)
	frame.fadeInfo = fadeInfo
	
	for i = 1, #FADEFRAMES do
		if FADEFRAMES[i] == frame then
			return
		end
	end
	tinsert(FADEFRAMES, frame)
	
	-- dummy frame to poke the Blizzard frameFadeManager awake, since its not directly accessible
	UIFrameFadeIn(wakeUp, 0)
end

local dummyFunc = function() end

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
		local inRange, checkedRange = UnitInRange(frame.displayedUnit)
		
		if checkedRange and not inRange then
			if list[frame] == db.minAlpha or isSliding then
				if frame.fadeInfo.finishedFunc then return end
				frame:SetAlpha(db.minAlpha)
				frame.background:SetAlpha(db.minBgAlpha)
			else
				FrameFade(frame, "OUT", db.timeToFade, db.maxAlpha, db.minAlpha)
				FrameFade(frame.background, "OUT", db.timeToFade, db.maxBgAlpha, db.minBgAlpha)
				list[frame] = db.minAlpha
				-- dummy func so it wont set alpha while doing a fading transition at the same time
				frame.fadeInfo.finishedFunc = dummyFunc
			end
		else
			if list[frame] == db.maxAlpha or isSliding then
				if frame.fadeInfo.finishedFunc then return end
				frame:SetAlpha(db.maxAlpha)
				frame.background:SetAlpha(db.maxBgAlpha)
			else
				FrameFade(frame, "IN", db.timeToFade, db.minAlpha, db.maxAlpha)
				FrameFade(frame.background, "IN", db.timeToFade, db.minBgAlpha, db.maxBgAlpha)
				list[frame] = db.maxAlpha
				frame.fadeInfo.finishedFunc = dummyFunc
			end
		end
	end)
	
	self:UnregisterEvent(event)
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)
