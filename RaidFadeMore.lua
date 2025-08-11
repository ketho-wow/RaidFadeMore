local NAME = ...
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local db

local defaults = {
	db_version = 2,

	minAlpha = .2,
	maxAlpha = 1,
}

local group = {
	part = true, -- party, only check char 1 to 4
	raid = true,
}

local f = CreateFrame("Frame")

local options = {
	type = "group",
	name = format("%s |cffADFF2F%s|r", NAME, C_AddOns.GetAddOnMetadata(NAME, "Version")),
	args = {
		group1 = {
			type = "group", order = 1,
			name = " ",
			inline = true,
			args = {
				minalpha = {
					type = "range", order = 1,
					width = "double", descStyle = "",
					name = "|cffFF0000Out of Range|r Alpha|r",
					get = function(i) return db.minAlpha end,
					set = function(i, v) db.minAlpha = v; f:RefreshFrames() end,
					min = 0, max = 1, step = .01,
				},
				spacing1 = {type = "description", order = 2, name = " "},
				maxalpha = {
					type = "range", order = 3,
					width = "double", descStyle = "",
					name = "|cff00FF00In Range|r Alpha",
					get = function(i) return db.maxAlpha end,
					set = function(i, v) db.maxAlpha = v; f:RefreshFrames() end,
					min = 0, max = 1, step = .01,
				},
				spacing2 = {type = "description", order = 4, name = " "},
				reset = {
					type = "execute", order = 5,
					width = "half", descStyle = "",
					name = RESET,
					func = function()
						RaidFadeMoreDB = CopyTable(defaults)
						db = RaidFadeMoreDB
						f:RefreshFrames()
					end,
				},
			},
		},
	},
}

function f:OnEvent(event, addon)
	if addon ~= NAME then return end

	if not RaidFadeMoreDB or defaults.db_version > RaidFadeMoreDB.db_version then
		RaidFadeMoreDB = CopyTable(defaults)
	end
	db = RaidFadeMoreDB

	ACR:RegisterOptionsTable(NAME, options)
	ACD:AddToBlizOptions(NAME, NAME)
	ACD:SetDefaultSize(NAME, 400, 280)

	-- FrameXML\CompactUnitFrame.lua
	hooksecurefunc("CompactUnitFrame_UpdateInRange", function(frame)
		if not frame.optionTable.fadeOutOfRange then return end
		if not group[strsub(frame.displayedUnit, 1, 4)] then return end -- ignore player, nameplates
		local inRange, checkedRange = UnitInRange(frame.displayedUnit)

		if checkedRange and not inRange then
			frame:SetAlpha(db.minAlpha)
			frame.background:SetAlpha(db.minAlpha)
		else
			frame:SetAlpha(db.maxAlpha)
			frame.background:SetAlpha(db.maxAlpha)
		end
	end)

	self:UnregisterEvent(event)
end

-- ever since the UNIT_IN_RANGE_UPDATE event we need to update the frames
-- when the slider options are changed for visual feedback
function f:RefreshFrames()
	for i = 1, 40 do
		local frame = _G["CompactRaidFrame"..i]
		if frame and frame.displayedUnit then
			CompactUnitFrame_UpdateInRange(frame)
		end
	end
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

for i, v in pairs({"rfm", "raidfade", "raidfademore"}) do
	_G["SLASH_RAIDFADEMORE"..i] = "/"..v
end

function SlashCmdList.RAIDFADEMORE()
	if not ACD.OpenFrames.RaidFadeMore then
		ACD:Open(NAME)
	end
end
