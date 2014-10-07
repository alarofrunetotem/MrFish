local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local toc=select(4,GetBuildInfo())
local me, ns = ...
local pp=print
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local C=LibStub("AlarCrayon-3.0"):GetColorTable()
local X=LibStub("AlarLoader-3.0")
X:loadingList(__FILE__,me)
X:GetPrintFunctions(me,ns)
local print=ns.print or print
local debug=ns.debug or print
-----------------------------------------------------------------
local addon=X:CreateAddon(me,true) --#MrFish
local FishingId=131474
local Fishing=''
local FishingIcon=''
local FishingPole
local FishingPoleId=6256
local FishingPolesCategory
local IsFishing
local CanFish
local NoPoleWarn=true
local weapons={
[INVSLOT_MAINHAND]={},
[INVSLOT_OFFHAND]={},
}
function addon:SKILL_LINES_CHANGED(...)
	self:Init()
end
function addon:PLAYER_REGEN_ENABLED()
	if (not IsFishing) then
		self.FishFrame:Hide()
		self.StopFrame:Hide()
	end
end
function addon:PLAYER_REGEN_DISABLED()
	local channeling=UnitChannelInfo("player")
	if (true or channeling == Fishing) then
		if (self:HasEquippedFishingPole()) then
			UIErrorsFrame:AddMessage(L["*** You dont have a weapon!!!! ***"], 1,0,0, 1.0, 40)
			self:StopFishFrame()
		end
	end
end
function addon:COMBAT_LOG_EVENT_UNFILTERED(_,timestamp,event,hidecaster,sguid,sname,sflags,sraidflags,dguid,dname,dflags,dRaidflags,spellid,spellname,stack,kind,...)
	if (bit.band(COMBATLOG_OBJECT_AFFILIATION_MINE,dflags)==1) then
		debug(event,sname,dname,spellid,'(',spellname,')',stack,kind,...)
		if (self.FishFrame and not InCombatLockdown()) then
			if (type(spellname)=="string" and spellname:find(Fishing)) then
				if (kind=="BUFF") then
					if (event == "SPELL_AURA_REMOVED") then
						if (IsFishing) then self:StartFishFrame(true) end
						self:StopFishFrame(false)
					elseif (event == "SPELL_AURA_APPLIED") then
						IsFishing=true
						self:StopFishFrame(true)
					end
				end
			end
		end
	end
end
function addon:PLAYER_EQUIPMENT_CHANGED(event,slot,hasItem)
	if (slot==INVSLOT_MAINHAND or slot==INVSLOT_OFFHAND) then
		local ID=GetInventoryItemID("player",slot)
		if (ID) then
			if (select(7,GetItemInfo(ID))==FishingPolesCategory) then
				FishingPole=GetItemInfo(ID)
				self:Fish(IsFishing)
				return
			else
				self:StoreWeapons()
				if (IsFishing) then self:NoFish() end
				return
			end
		end
	end
	if (not InCombatLockdown()) then
	FishingPole=self:GetFishingPole()
	end
end
function addon:HasEquippedFishingPole()
	local ID=GetInventoryItemID("player",INVSLOT_MAINHAND)
	if (ID) then
			if (select(7,GetItemInfo(ID))==FishingPolesCategory) then
				return ID
			else
				return false
			end
	else
			return 0
	end
end
function addon:GetFishingPole()
	-- Discover localized category name
	local maxlevel=0
	local maxname
	print(format(L["Searching your bags for %s"],FishingPolesCategory))
	for bag=BACKPACK_CONTAINER,NUM_BAG_SLOTS,1 do
		for slot=1,GetContainerNumSlots(bag),1 do
			local ID=GetContainerItemID(bag,slot)
			if (ID) then
				local name,itemlink,_,level,_,_,cat=GetItemInfo(ID)
				if (cat==FishingPolesCategory) then
					if (level>maxlevel) then
						maxname=name
						maxlevel=level
					end
				end
			end
		end
	end
	if (maxname) then
		print(format(L["Found %s"],maxname))
	end
	return maxname
end
function addon:Info(...)
	print(...)
	for k,v in pairs(weapons) do
	if (v) then
		print(k,"=",v.name)
	end
	end
	if (FishingPole) then
	print(format(L["Fishing pole is %s"],GetItemInfo(FishingPole)))
	end
end
local function pushWeapon(tb,...)
	if (select(1,...)) then
		if (select(7,...) == FishingPolesCategory) then return end
		tb.name=select(1,...)
		tb.skin=select(10,...)
	end
end
function addon:StoreWeapons()
	local id=GetInventoryItemID("player",INVSLOT_MAINHAND)
	if (id) then pushWeapon(weapons[INVSLOT_MAINHAND],GetItemInfo(id)) end
	id=GetInventoryItemID("player",INVSLOT_OFFHAND)
	if (id) then pushWeapon(weapons[INVSLOT_OFFHAND],GetItemInfo(id)) end
end
function addon:RestoreWeapons()
	if (weapons[INVSLOT_MAINHAND].name) then EquipItemByName(weapons[INVSLOT_MAINHAND].name) end
	if (weapons[INVSLOT_OFFHAND].name) then EquipItemByName(weapons[INVSLOT_OFFHAND].name) end
end
function addon:OnInitialized()
	print(format("Questa non ha %%s",'pippo'))
	Fishing,_,FishingIcon=GetSpellInfo(FishingId)
	self:Discovery()
	return true
end
function addon:Discovery()
	FishingPolesCategory=select(7,GetItemInfo(FishingPoleId))
	Fishing,_,FishingIcon=GetSpellInfo(FishingId)
	if (not FishingPolesCategory or not Fishing) then
		self:ScheduleTimer("Discovery",2)
	else
		self:Init()
	end
end
function addon:ApplyRESTORE(value)
	if (true) then
		self:RegisterEvent("PLAYER_LOGOUT","RestoreWeapons")
	else
		self:UnregisterEvent("PLAYER_LOGOUT")
	end
end
function addon:Init()
	self:StoreWeapons()
	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
	if (fishing) then
		CanFish = true
	end
	if (CanFish) then
		self:GenerateFrame()
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:AddToggle("RESTORE",true,L["Restore weapons on logout"],L["Always attempts to restore weapon on logout"])
		self:AddChatCmd("fish","Fish")
		self:AddChatCmd("nofish","NoFish")
		FishingPole=self:GetFishingPole()
		self:AddPrivateOpenCmd("info","Info")
		self:loadHelp()
		self:UnregisterEvent("SKILL_LINES_CHANGED")
	else
		self:RegisterEvent("SKILL_LINES_CHANGED")
		print(L["You should learn to fish, before fishing!"])
	end
end
function addon:StartFishFrame(atCursor)
	IsFishing=true
	local f=self.FishFrame
	f:SetMacrotext("/stopcasting\n/equip " .. (FishingPole or '') .. "\n/cast " .. Fishing,'','')
	f:SetIcon("Interface\\Icons\\Trade_Fishing")
	f:SetCloseMacro("/stopcasting")
	f:SetCallback("OnClick",function(this)
				this:FadeStop()
				this:FadeOut(5)
	end)
	if (atCursor) then
	f:ShowAtMouse()
	else
	f:ShowAtCenter()
	end
end
function addon:StopFishFrame(show)
	local body,main,off='/stopcastinc',weapons[INVSLOT_MAINHAND].name,weapons[INVSLOT_OFFHAND].name
	if (main and off) then
			body=format("/stopcasting\n/equip %s\n/equip %s",main,off)
	elseif (main or off) then
			body=format("/stopcasting\n/equip %s",main or off)
	else
			body='/stopcasting'
	end
	local f=self.StopFrame
	f:SetModifiedCast('','macrotext',1,body)
	if (show) then
	f:Show()
	else
	f:Hide()
	end
end
function addon:GenerateFrame()
		self.FishFrame=LibStub("AceGUI-3.0"):Create("AlarCastSingleButton")
		local f=self.FishFrame
		f:Hide()
		f:SetMacrotext("/stopcasting\n/equip " .. (FishingPole or '') .. "\n/cast " .. Fishing,'','')
		f:SetIcon("Interface\\Icons\\Trade_Fishing")
		f:SetCloseMacro("/stopcasting")
		f:SetCallback("OnFadeEnd",function(this) end)
		f:SetCallback("OnClose",function(this)  self:NoFish() end )
		f:SetTitleWidth(0)
		self.StopFrame=LibStub("AceGUI-3.0"):Create("AlarCastHeader")
		local f=self.StopFrame
		f:Hide()
		f:SetTitle(BINDING_NAME_STOPCASTING .. ": " .. Fishing)
		f:AutoSize()
		f:SetCallback("OnClick",function() addon:NoFish() end)
end

function addon:NoFish()
	if (not InCombatLockdown()) then
		if (IsEquippedItemType(FishingPolesCategory)) then self:RestoreWeapons() end
		self.FishFrame:FadeStop()
		self.FishFrame:Hide()
		self.StopFrame:Hide()
	end
	IsFishing=false
end
function addon:EquipFishingPole()
	if (InCombatLockdown()) then
		UIErrorsFrame:AddMessage(L["Better stick to fighting"], 1,0,0, 1.0, 40)
		return
	end
	if (not IsEquippedItemType(FishingPolesCategory)) then
		FishingPole=self:GetFishingPole()
		if (not FishingPole and NoPoleWarn) then
			UIErrorsFrame:AddMessage(format(L["Maybe you want to buy a %s"] , FishingPolesCategory), 1,0,0, 1.0, 40)
			NoPoleWarn=false
		else
				self:StoreWeapons()
				EquipItemByName(FishingPole)
			end
	end
end
function addon:Fish(atCursor)
	if (not UnitChannelInfo("player")) then
		self:EquipFishingPole()
	end
	self:StartFishFrame(atCursor)
	IsFishing=true
end
_G.FISH=addon