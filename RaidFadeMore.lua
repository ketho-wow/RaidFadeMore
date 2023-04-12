local NAME = ...
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local db

local defaults = {
	db_version = .8,

	minAlpha = .2,
	maxAlpha = 1,

	minBgAlpha = .5,
	maxBgAlpha = 1,
}

local group = {
	part = true, -- party, only check char 1 to 4
	raid = true,
}

local options = {
	type = "group",
	name = format("%s |cffADFF2F%s|r", NAME, GetAddOnMetadata(NAME, "Version")),
	args = {
		group1 = {
			type = "group", order = 1,
			name = " ",
			inline = true,
			args = {
				minalpha = {
					type = "range", order = 1,
					width = "double", descStyle = "",
					name = "|cff71D5FFOut of Range Alpha|r",
					get = function(i) return db.minAlpha end,
					set = function(i, v) db.minAlpha = v end,
					min = 0, max = 1, step = .01,
				},
				spacing1 = {type = "description", order = 2, name = " "},
				minBgAlpha = {
					type = "range", order = 3,
					width = "double", descStyle = "",
					name = "|cff71D5FFOut of Range "..BACKGROUND.." Alpha|r",
					get = function(i) return db.minBgAlpha end,
					set = function(i, v) db.minBgAlpha = v end,
					min = 0, max = 1, step = .01,
				},
				spacing2 = {type = "description", order = 4, name = " "},
				maxalpha = {
					type = "range", order = 5,
					width = "double", descStyle = "",
					name = "|cff71D5FFIn Range Alpha|r",
					get = function(i) return db.maxAlpha end,
					set = function(i, v) db.maxAlpha = v end,
					min = 0, max = 1, step = .01,
				},
				spacing3 = {type = "description", order = 6, name = " "},
				maxBgAlpha = {
					type = "range", order = 7,
					width = "double", descStyle = "",
					name = "|cff71D5FFIn Range "..BACKGROUND.." Alpha|r",
					get = function(i) return db.maxBgAlpha end,
					set = function(i, v) db.maxBgAlpha = v end,
					min = 0, max = 1, step = .01,
				},
				spacing4 = {type = "description", order = 8, name = " "},
				reset = {
					type = "execute", order = 9,
					width = "half", descStyle = "",
					name = RESET,
					func = function()
						RaidFadeMoreDB = CopyTable(defaults)
						db = RaidFadeMoreDB
					end,
				},
			},
		},
	},
}

local f = CreateFrame("Frame")

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
		if not group[strsub(frame.displayedUnit, 1, 4)] then return end -- ignore player, nameplates
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

for i, v in pairs({"rfm", "raidfade", "raidfademore"}) do
	_G["SLASH_RAIDFADEMORE"..i] = "/"..v
end

function SlashCmdList.RAIDFADEMORE()
	if not ACD.OpenFrames.RaidFadeMore then
		ACD:Open(NAME)
	end
end
