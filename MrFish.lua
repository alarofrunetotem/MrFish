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
local dump=ns.dump or print
local sdebug=ns.sdebug or print
-----------------------------------------------------------------
local addon=X:CreateAddon(me,true) --#MrFish
local FishingId=131474
local Fishing=''
local FishingIcon=''
local FishingPole
local FishingPoleId=6256
local FishingPolesCategory
local IsFishing
local weapons={
[INVSLOT_MAINHAND]=nil,
[INVSLOT_OFFHAND]=nil,
}
function addon:prova(...)
	local a=''
	if (InCombatLockdown()) then a ="COMBAT" end
	print(a,...)
end
function addon:PLAYER_REGEN_DISABLED()
	self:NoFish()
end
function addon:COMBAT_LOG_EVENT_UNFILTERED(_,timestamp,event,hidecaster,sguid,sname,sflags,sraidflags,dguid,dname,dflags,dRaidflags,spellid,spellname,stack,kind,...)
	if (bit.band(COMBATLOG_OBJECT_AFFILIATION_MINE,dflags)==1) then
		debug(event,sname,dname,spellid,'(',spellname,')',stack,kind,...)
		if (self.FishFrame and not InCombatLockdown()) then
			if (type(spellname)=="string" and spellname:find(Fishing)) then
				if (kind=="BUFF") then
					if (event == "SPELL_AURA_REMOVED") then
						self:Fish(true)
					elseif (event == "SPELL_AURA_APPLIED") then
						if (not IsFishing) then self:Fish() end
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
			IsFishing=select(7,GetItemInfo(ID))==FishingPolesCategory
			if (IsFishing) then
				FishingPole=GetItemInfo(ID)
				self:Fish()
			else
				self:StoreWeapons()
				if (IsFishing) then self:NoFish() end
			end
		end
	end
end
function addon:GetFishingPole()
	-- Discover localized category name
	print(format(L["Scanning your bags for %s"],FishingPolesCategory))
	for bag=BACKPACK_CONTAINER,NUM_BAG_SLOTS,1 do
		for slot=1,GetContainerNumSlots(bag),1 do
			local ID=GetContainerItemID(bag,slot)
			if (ID) then
				local name,itemlink,_,_,_,_,cat=GetItemInfo(ID)
				if (cat==FishingPolesCategory) then
					return name
				end
			end
		end
	end
end
function addon:Info(...)
	print(...)
	for k,v in pairs(weapons) do
	if (v) then
		print(k,"=",GetItemInfo(v),"")
	end
	end
	if (FishingPole) then
	print(format(L["Fishing pole is %s"],GetItemInfo(FishingPole)))
	end
end
function addon:StoreWeapons()
	weapons[INVSLOT_MAINHAND]=GetInventoryItemID("player",INVSLOT_MAINHAND)
	weapons[INVSLOT_OFFHAND]=GetInventoryItemID("player",INVSLOT_OFFHAND)
	self:Info()
end
function addon:RestoreWeapons()
	if (weapons[INVSLOT_MAINHAND]) then EquipItemByName(weapons[INVSLOT_MAINHAND]) end
	if (weapons[INVSLOT_OFFHAND]) then EquipItemByName(weapons[INVSLOT_OFFHAND]) end
end
function addon:OnInitialized()
	Fishing,_,FishingIcon=GetSpellInfo(FishingId)
	self:Discovery()
	return true
end
function addon:Discovery()
	FishingPolesCategory=select(7,GetItemInfo(FishingPoleId))
	if (not FishingPolesCategory) then
		debug("Attempt to load category")
		sdebug("sAttempt to load category")
		self:ScheduleTimer("discovery",2)
	else
		self:Init()
	end
end
function addon:Init()
	self:StoreWeapons()
	if (Fishing) then
		self:GenerateFrame()
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:AddChatCmd("fish","Fish")
		self:AddChatCmd("nofish","Fish")
		self:GetFishingPole()
		self:AddOpenCmd("info","Info")
		self:loadHelp()
	else
		print(L["You can't fish!"])
	end
end
function addon:GenerateFrame()
		local f=LibStub("AceGUI-3.0"):Create("AlarCastSingleButton")
		f:Hide()
		f:SetSpell(Fishing)
		f:SetModifiedCast(f.frame,'',2,Fishing)
		f:SetCallback("OnClick",function(this)
					self:EquipFishingPole()
					this:FadeStop()
					this:FadeOut(5)
		end)
		f:SetCallback("OnFadeEnd",function(this) end)
		f:SetCallback("OnClose",function(this)  self:NoFish() end )
		f:SetTitleWidth(0)
		self.FishFrame=f
end
function addon:NoFish()
	if (IsEquippedItemType(FishingPolesCategory)) then
		self:RestoreWeapons()
	end
	self.FishFrame:Hide()
	IsFishing=false
end
function addon:EquipFishingPole()
	if (InCombatLockdown()) then
		UIErrorsFrame:AddMessage(L["Better stick to fighting"], 1,0,0, 1.0, 40)
		return
	end
	if (not IsEquippedItemType(FishingPolesCategory)) then
		if (not FishingPole) then
			FishingPole=self:GetFishingPole()
		end
		if (not FishingPole) then
			UIErrorsFrame:AddMessage(format(L["Maybe you want to buy a %s"] , FishingPolesCategory), 1,0,0, 1.0, 40)
		else
				self:StoreWeapons()
				EquipItemByName(FishingPole)
			end
	end
end
function addon:Fish(atCursor)
	self:EquipFishingPole()
	if (type(atCursor)=="boolean" and atCursor) then
	self.FishFrame:ShowAtMouse()
	else
	self.FishFrame:ShowAtCenter()
	end
	IsFishing=true
end
_G.FISH=addon