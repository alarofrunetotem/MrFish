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
-----------------------------------------------------------------
local addon=X:CreateAddon(me,true) --#MrFish
local FishingId=131474
local Fishing=''
local FishingIcon=''
local FishingPole
local FishingPoleId=6256
local FishingPolesCategory
local weapons={
[INVSLOT_MAINHAND]=nil,
[INVSLOT_OFFHAND]=nil,
}
function addon:prova(...)
	local a=''
	if (InCombatLockdown()) then a ="COMBAT" end
	print(a,...)
end
function addon:UNIT_SPELLCAST_SUCCEEDED(event,unit,...)
	if (unit=="player") then
		print(event,...)
	end
end
function addon:PLAYER_REGEN_DISABLED()
	self:ScheduleLeaveCombatAction("NoFish")
end
function addon:COMBAT_LOG_EVENT_UNFILTERED(_,timestamp,event,hidecaster,sguid,sname,sflags,sraidflags,dguid,dname,dflags,dRaidflags,spellid,spellname,stack,kind,...)
		if (bit.band(COMBATLOG_OBJECT_AFFILIATION_MINE,dflags)==1) then
				debug(event,sname,dname,spellid,'(',spellname,')',stack,kind,...)
				if (event == "SPELL_AURA_REMOVED" and kind=="BUFF") then
					local arg=spellname
					-- Fishing check
					if self.FishFrame then
						if (not InCombatLockdown()) then
								if (arg:find(Fishing)) then
										self.FishFrame:ShowAtMouse()
										RegisterAutoHide(self.FishFrame.frame,1)
										return
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
			end
		end
	end
end
function addon:GetFishingPole()
	-- Discover localized category name
	local Category=select(7,GetItemInfo(FishingPoleId))
	print(L["Scanning your bags for"],Category)
	for bag=BACKPACK_CONTAINER,NUM_BAG_SLOTS,1 do
		for slot=1,GetContainerNumSlots(bag),1 do
			local ID=GetContainerItemID(bag,slot)
			if (ID) then
				local name,itemlink,_,_,_,_,cat=GetItemInfo(ID)
				if (cat==Category) then
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
	print("Fishing pole is",GetItemInfo(FishingPole))
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
	FishingPolesCategory=select(7,GetItemInfo(FishingPoleId))
	self:StoreWeapons()
	if (Fishing) then
		self:GenerateFrame()
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:AddChatCmd("fish","Fish")
		self:GetFishingPole()
		self:AddChatCmd("myfish","Info")
		self:loadHelp()
	else
		print(L["You can't fish!"])
	end
	return true
end
function addon:GenerateFrame()
		local f=LibStub("AceGUI-3.0"):Create("AlarCastSingleButton")
		f:Hide()
		f:SetSpell(Fishing)
		f:SetCallback("OnClick",function(this) print("OnClick Fishing") this:FadeStop() this:FadeOut(5) end)
		f:SetCallback("OnFadeEnd",function(this) print("FadeEnd Fishing") this:FadeStop() this:FadeOut(5) end)
		f:SetCallback("OnClose",function(this)  self:NoFish() end )
		self.FishFrame=f
end
function addon:NoFish()
	if (IsEquippedItemType(FishingPolesCategory)) then
		self:RestoreWeapons()
	end
	self.FishFrame:Hide()
	IsFishing=false
end
function addon:Fish()
	if (InCombatLockdown()) then
		UIErrorsFrame:AddMessage(L["Better stick to fighting"], 1,0,0, 1.0, 40)
		return
	end
	if (not FishingPole) then
		FishingPole=self:GetFishingPole()
	end
	if (not FishingPole) then
		UIErrorsFrame:AddMessage(L["Maybe you want to buy a "] .. FishingPolesCategory, 1,0,0, 1.0, 40)
	else
		if (not IsEquippedItemType(FishingPolesCategory)) then
			self:StoreWeapons()
			EquipItemByName(FishingPole)
		end
	end
	self.FishFrame:ShowAtCenter()

end
_G.FISH=addon
pp("mrfish caricato")