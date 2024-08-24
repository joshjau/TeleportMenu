local _, tp = ...

local APPEND = "\124cFFFF0000TeleportMenu:\124r "
local availableHearthstones = {}
local validHearthstoneToys = {
	[54452] = true, -- Ethereal Portal
	[64488] = true, -- The Innkeeper's Daughter
	[93672] = true, -- Dark Portal
	[142542] = true, -- Tome of Town Portal
	[162973] = true, -- Greatfather Winter's Hearthstone
	[163045] = true, -- Headless Horseman's Hearthstone
	[163206] = true, -- Weary Spirit Binding
	[165669] = true, -- Lunar Elder's Hearthstone
	[165670] = true, -- Peddlefeet's Lovely Hearthstone
	[165802] = true, -- Noble Gardener's Hearthstone
	[166746] = true, -- Fire Eater's Hearthstone
	[166747] = true, -- Brewfest Reveler's Hearthstone
	[168907] = true, -- Holographic Digitalization Hearthstone
	[172179] = true, -- Eternal Traveler's Hearthstone
	[180290] = function() -- Night Fae Hearthstone
		local covenantID = C_Covenants.GetActiveCovenantID()
		if covenantID == 3 then return true end
	end,
	[182773] = function() -- Necrolord Hearthstone
		local covenantID = C_Covenants.GetActiveCovenantID()
		if covenantID == 4 then return true end
	end,
	[183716] = function() -- Venthyr Sinstone
		local covenantID = C_Covenants.GetActiveCovenantID()
		if covenantID == 2 then return true end
	end,
	[184353] = function() -- Kyrian Hearthstone
		local covenantID = C_Covenants.GetActiveCovenantID()
		if covenantID == 1 then return true end
	end,
	[188952] = true, -- Dominated Hearthstone
	[190196] = true, -- Enlightened Hearthstone
	[190237] = true, -- Broker Translocation Matrix
	[193588] = true, -- Timewalker's Hearthstone
	[200630] = true, -- Ohnir Windsage's Hearthstone
	[206195] = true, -- Path of the Naaru
	[208704] = true, -- Deepdweller's Earthen Hearthstone
	[209035] = true, -- Hearthstone of the Flame
	[210455] = function() -- Draenic Hologem (Draenei and Lightforged Draenei only)
		local _, _, raceId = UnitRace("player")
		if raceId == 11 or raceId == 30 then return true end
	end,
	[212337] = true, -- Stone of the Hearth
}

local wormholes = {
	[48933] = true, -- Wormhole Generator: Northrend
	[87215] = true, -- Wormhole Generator: Pandaria
	[112059] = true, -- Wormhole Centrifuge (Dreanor)
	[151652] = true, -- Wormhole Generator: Argus
	[168807] = true, -- Wormhole Generator: Kul Tiras
	[168808] = true, -- Wormhole Generator: Zandalar
	[172924] = true, -- Wormhole Generator: Shadowlands
	[221966] = true, -- Wormhole Generator: Khaz Algar
}

local tpTable = {
	{id = 6948, type = "item", hearthstone = true}, -- Hearthstone
	{id = 110560, type = "toy", quest={34378, 34586}}, -- Garrison Hearthstone
	{id = 140192, type = "toy", quest={44184, 44663}}, -- Dalaran Hearthstone
	{id = 1, type = "flyout", iconId = 237509}, -- Teleport (Mages)
	{id = 8, type = "flyout", iconId = 237509}, -- Teleport (Mages)
	{id = 11, type = "flyout", iconId = 135744}, -- Portals (Mages)
	{id = 12, type = "flyout", iconId = 135748}, -- Portals (Mages)
	{id = 230, type = "flyout", iconId = 574788}, -- Hero's Path: Cataclysm
	{id = 84, type = "flyout", iconId = 328269}, -- Hero's Path: Mists of Pandaria
	{id = 96, type = "flyout", iconId = 1413856}, -- Hero's Path: Warlords of Draenor
	{id = 224, type = "flyout", iconId = 1260827}, -- Hero's Path: Legion
	{id = 223, type = "flyout", iconId = 1869493}, -- Hero's Path: Battle for Azeroth
	{id = 220, type = "flyout", iconId = 236798}, -- Hero's Path: Shadowlands
	{id = 222, type = "flyout", iconId = 4062765}, -- Hero's Path: Shadowlands Raids
	{id = 227, type = "flyout", iconId = 4640496}, -- Hero's Path: Dragonflight
	{id = 231, type = "flyout", iconId = 5342925}, -- Hero's Path: Dragonflight Raids
	--{id = 233, type = "flyout", iconId = 5872031}, -- Hero's Path: The War Within
}

local function updateAvailableHearthstones()
	availableHearthstones = {}
	for id, usable in pairs(validHearthstoneToys) do
		if PlayerHasToy(id) then
			if type(usable) == "function" and usable() then
				table.insert(availableHearthstones, id)
			elseif usable == true then
				table.insert(availableHearthstones, id)
			end
		end
	end
end

local function updateAvailableWormholes()
	for id, _ in pairs(wormholes) do
		if PlayerHasToy(id) and C_ToyBox.IsToyUsable(id) then
			table.insert(tpTable, {id = id, type = "toy"})
		end
	end
end

local function checkQuestCompletion(quest)
	if type(quest) == "table" then
		for _, questID in ipairs(quest) do
			if C_QuestLog.IsQuestFlaggedCompleted(questID) then
				return true
			end
		end
	else
		return C_QuestLog.IsQuestFlaggedCompleted(quest)
	end
end

local function setCombatTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMLEFT", TeleportMeButtonsFrame, "TOPRIGHT", 0, 0)
	GameTooltip:SetText("\124cFFFF0000<Not available in combat>\124r", 1, 1, 1)
	GameTooltip:Show()
end

local function setToolTip(self, type, id, hs)
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMLEFT", TeleportMeButtonsFrame, "TOPRIGHT", 0, 0)
	if hs and TeleportMenuDB.hearthstone and TeleportMenuDB.hearthstone == "rng" then
		GameTooltip:SetText("Random Hearthstone", 1, 1, 1)
		GameTooltip:AddLine("\124cFF34B7EBClick to cast a random hearthstone.\nIt will pick a new hearthstone when you re-open the menu.\124r", 1, 1, 1)
		GameTooltip:Show()
	elseif type == "item" then
		GameTooltip:SetItemByID(id)
	elseif type == "toy" then
		GameTooltip:SetToyByItemID(id)
	elseif type == "spell" then
		GameTooltip:SetSpellByID(id)
	elseif type == "flyout" then
		local name = GetFlyoutInfo(id)
		GameTooltip:SetText(name, 1, 1, 1)
	end
	GameTooltip:Show()
end

local function createCooldownFrame(frame)
	if frame.cooldownFrame then return frame.cooldownFrame end
    local cooldownFrame = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldownFrame:SetAllPoints()

	function cooldownFrame:CheckCooldown(id, type)
		local start, duration, enabled
		if type == "toy" or type == "item" then
			start, duration, enabled = C_Item.GetItemCooldown(id)
		else
			local cooldown = C_Spell.GetSpellCooldown(id)
			start = cooldown.startTime
			duration = cooldown.duration
			enabled = true
		end
		if enabled and duration > 0 then
			self:SetCooldown(start, duration)
		else
			self:Clear()
		end
	end

	return cooldownFrame
end

local function retryTexture(button, itemId, attempt)
	local attempts = attempt or 1
	local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(itemId)
	if itemTexture then
		button:SetNormalTexture(itemTexture)
		return
	end
	if attempts < 5 then
		C_Timer.After(1, function()
			retryTexture(button, itemId, attempts + 1)
		end)
	else
		print(APPEND.."a texture is missing for itemID: "..itemId..", please report this to the author.")
	end
end

local function updateHearthstone()
	local hearthstoneButton = TeleportMeButtonsFrame.hearthstoneButton
	if not hearthstoneButton then return end
	local texture
	if TeleportMenuDB.hearthstone == "rng" then
		texture = 1669494 -- misc_rune_pvp_random
		local rng = math.random(#availableHearthstones)
		hearthstoneButton:SetAttribute("type", "toy")
		hearthstoneButton:SetAttribute("toy", availableHearthstones[rng])
	elseif TeleportMenuDB.hearthstone then
		local _, _, iconId = C_ToyBox.GetToyInfo(TeleportMenuDB.hearthstone)
		texture = iconId
		hearthstoneButton:SetAttribute("type", "toy")
		hearthstoneButton:SetAttribute("toy", TeleportMenuDB.hearthstone)
	else
		local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(6948)
		texture = itemTexture
		hearthstoneButton:SetAttribute("type", "item")
		hearthstoneButton:SetAttribute("item", "item:6948")
	end
	hearthstoneButton:SetNormalTexture(texture)
end

local function GetRandomHearthstone(retry)
	if #availableHearthstones == 0 then return end
	if #availableHearthstones == 1 then return availableHearthstones[1] end -- Don't even bother
	local randomHs = availableHearthstones[math.random(#availableHearthstones)]
	if lastRandomHearthstone == randomHs then -- Don't fully randomize, always a new one
		randomHs = GetRandomHearthstone(true)
	end
	if not retry then
		lastRandomHearthstone = randomHs
	end
	return randomHs
end

local function createAnchors()
	if InCombatLockdown() then
		return
	elseif TeleportMeButtonsFrame then
		if TeleportMenuDB.hearthstone and TeleportMenuDB.hearthstone == "rng" then
			TeleportMeButtonsFrame.hearthstoneButton:SetAttribute("toy", GetRandomHearthstone())
		end
		return
	end
	local buttonsFrame = CreateFrame("Frame", "TeleportMeButtonsFrame", GameMenuFrame)
	buttonsFrame:SetSize(1, 1)
	buttonsFrame:SetPoint("TOPLEFT", GameMenuFrame, "TOPRIGHT", 0, 0)

	local created = 0
	for i, tp in ipairs(tpTable) do
		if tp.hearthstone and TeleportMenuDB.hearthstone then -- Overwrite main HS with user set HS
			tp.type = "toy"
			if TeleportMenuDB.hearthstone == "rng" then
				tp.id = GetRandomHearthstone()
			else
				tp.id = TeleportMenuDB.hearthstone
			end
		end
		local texture
		local known
		local flyOutSpellsKnown
		if tp.hearthstone and TeleportMenuDB.hearthstone and TeleportMenuDB.hearthstone == "rng" then
			texture = 1669494 -- misc_rune_pvp_random
			known = true
		elseif tp.type == "item" then
			local _, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(tp.id)
        	texture = itemTexture
			known = GetItemCount(tp.id) > 0
		elseif tp.type == "toy" and PlayerHasToy(tp.id) then
			local _, name, iconId = C_ToyBox.GetToyInfo(tp.id)
			texture = iconId
			if tp.quest then
				known = checkQuestCompletion(tp.quest)
			else
				known = true
			end
		elseif tp.type == "flyout" then
			local name, desc, amount, flyoutKnown = GetFlyoutInfo(tp.id)
			if flyoutKnown then
				flyOutSpellsKnown = amount
				texture = tp.iconId
				known = flyoutKnown
			end
		end
		if known and (tp.type == "toy" or tp.type == "item") then
			created = created + 1
			local button = CreateFrame("Button", nil, buttonsFrame," SecureActionButtonTemplate");
			local yOffset = 40 + (-40 * created)
			button:SetSize(40, 40)
			if not texture then
				C_Timer.After(0.7, function()
					retryTexture(button, tp.id)
				end)
				texture = "Interface\\Icons\\INV_Misc_QuestionMark"
			end
			button:SetNormalTexture(texture)
			if tp.type == "item" then
				button:SetAttribute("type", tp.type)
				button:SetAttribute(tp.type, "item:"..tp.id)
			else
				button:SetAttribute("type", tp.type)
				button:SetAttribute(tp.type, tp.id)
			end
			button:SetPoint("TOPLEFT", buttonsFrame, "TOPRIGHT", 0, yOffset)
			button:EnableMouse(true)
			button:RegisterForClicks("AnyDown", "AnyUp")
			button:SetFrameStrata("HIGH")
			button:SetFrameLevel(101)
			button.cooldownFrame = createCooldownFrame(button)
			button.cooldownFrame:CheckCooldown(tp.id, tp.type)
			button:SetScript("OnEnter", function(self)
				setToolTip(self, tp.type, tp.id, tp.hearthstone)
			end)
			button:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
			button:SetScript("OnShow", function(self)
				self.cooldownFrame:CheckCooldown(tp.id, tp.type)
			end)

			if tp.hearthstone then -- store to replace item later
				buttonsFrame.hearthstoneButton = button
			end
		elseif known and tp.type == "flyout" then
			created = created + 1
			local button = CreateFrame("Button", nil, buttonsFrame, "SecureActionButtonTemplate");
			local yOffset = 40 + (-40 * created)
			button:SetSize(40, 40)
			button:SetNormalTexture(texture)
			button:SetPoint("TOPLEFT", buttonsFrame, "TOPRIGHT", 0, yOffset)
			button:EnableMouse(true)
			button:RegisterForClicks("AnyDown", "AnyUp")
			button:SetFrameStrata("HIGH")
			button:SetFrameLevel(101)
			button:SetScript("OnEnter", function(self)
				if InCombatLockdown() then
					setCombatTooltip(self)
					return
				end
				setToolTip(self, tp.type, tp.id)
				self.flyOutFrame:Show()
			end)
			button:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			local flyOutFrame = CreateFrame("Frame", nil, buttonsFrame);
			flyOutFrame:SetPoint("TOPLEFT", buttonsFrame, "TOPRIGHT", 0, yOffset)
			flyOutFrame:SetFrameStrata("HIGH")
			flyOutFrame:SetFrameLevel(103)
			flyOutFrame:SetPropagateMouseClicks(true)
			flyOutFrame:SetPropagateMouseMotion(true)
			flyOutFrame.mainButton = button
			flyOutFrame:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
				if not InCombatLockdown() then
					self:Hide()
				end
			end)
			flyOutFrame:Hide()
			button.flyOutFrame = flyOutFrame

			local flyOutButtons = {}
			local flyoutsCreated = 0
			for i = 1, flyOutSpellsKnown do
				local spellID = select(1, GetFlyoutSlotInfo(tp.id, i))
				if IsSpellKnown(spellID) then
					flyoutsCreated = flyoutsCreated + 1
					local xOffset = 40 * flyoutsCreated
					local spellName = C_Spell.GetSpellName(spellID)
					local spellTexture = C_Spell.GetSpellTexture(spellID)
					local flyOutButton = CreateFrame("Button", nil, flyOutFrame," SecureActionButtonTemplate");
					flyOutButton:SetSize(40, 40)
					flyOutButton:SetNormalTexture(spellTexture)
					flyOutButton:SetAttribute("type", "spell")
					flyOutButton:SetAttribute("spell", spellID)
					flyOutButton:SetPoint("RIGHT", flyOutFrame, "LEFT", 40 + xOffset, 0)
					flyOutButton:EnableMouse(true)
					flyOutButton:RegisterForClicks("AnyDown", "AnyUp")
					flyOutButton:SetFrameStrata("HIGH")
					flyOutButton:SetFrameLevel(102)
					flyOutButton:SetScript("OnEnter", function(self)
						setToolTip(self, "spell", spellID)
					end)
					flyOutButton:SetScript("OnLeave", function(self)
						GameTooltip:Hide()
					end)
					flyOutButton.cooldownFrame = createCooldownFrame(flyOutButton)
					flyOutButton.cooldownFrame:CheckCooldown(spellID)
					flyOutButton:SetScript("OnShow", function(self)
						self.cooldownFrame:CheckCooldown(spellID)
					end)
					table.insert(flyOutButtons, flyOutButton)
				end
			end

			flyOutFrame:SetSize(40 + (40 * flyoutsCreated), 40)

			button.flyOutButtons = flyOutButtons
		end
	end
end

-- Slash Commands
SLASH_TPMENU1 = "/tp"
SLASH_TPMENU2 = "/tpmenu"
SlashCmdList["TPMENU"] = function(msg)
	if msg == "clear" then
		TeleportMenuDB.hearthstone = nil
		updateHearthstone()
		print(APPEND.."Hearthstone reset to default!")
		return
	end

	if msg == "list" then
		print(APPEND.."Available Hearthstone toys: [id - name]")
		for id, _ in pairs(validHearthstoneToys) do
			if PlayerHasToy(id) then
				local _, name = C_ToyBox.GetToyInfo(id)
				print(id.." - "..name)
			end
		end
		return
	end

	if msg == "rng" then
		if not availableHearthstones or #availableHearthstones == 0 then
			print(APPEND.."You don't have any valid Hearthstone toys to randomize in your collection.")
			return
		end
		TeleportMenuDB.hearthstone = msg
		updateHearthstone()
		return
	end

    local id = tonumber(msg)
	if id and validHearthstoneToys[id] and PlayerHasToy(id) then
		local _, name = C_ToyBox.GetToyInfo(id)
		TeleportMenuDB.hearthstone = id
		updateHearthstone()
		print(APPEND.."New Hearthstone set to: "..name.."!")
	else
		print(APPEND.."Available Commands:")
		print("/tp list - List all valid Hearthstone toys in your collection.")
		print("/tp clear - Reset back to the default hearthstone.")
		print("/tp [itemId] - Set a valid Hearthstone toy as your alternative Hearthstone.")
		print("/tp rng - Randomize a Hearthstone toy from your collection every time you open the game menu.")
	end
end

-- Loading
local function OnEvent(self, event, addOnName)
	if addOnName == "TeleportMenu" then
		TeleportMenuDB = TeleportMenuDB or {}
		C_Timer.After(5, function()
			if TeleportMenuDB.hearthstone and TeleportMenuDB.hearthstone ~= "rng" and not PlayerHasToy(TeleportMenuDB.hearthstone) then
				print(APPEND.."We reset your heartstone to default because the toy with itemID: "..TeleportMenuDB.hearthstone.." is not in your collection.")
				TeleportMenuDB.hearthstone = nil
				updateHearthstone()
			end
		end)
    elseif event == "PLAYER_LOGIN" then
		updateAvailableHearthstones()
		updateAvailableWormholes()
		createAnchors()
		hooksecurefunc("ToggleGameMenu", createAnchors)
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", OnEvent)
