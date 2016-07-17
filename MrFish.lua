local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me,ns=...
--@debug@
LoadAddOn("Blizzard_DebugTools")
LoadAddOn("LibDebug")
if LibDebug then LibDebug() end
--@end-debug@
--[===[@non-debug@
local print=function() end
local DevTools_Dump=function() end
--@end-non-debug@]===]
local addon --#MailCommander
local LibInit,minor=LibStub("LibInit",true)
assert(LibInit,me .. ": Missing LibInit, please reinstall")
if minor >=21 then
	addon=LibStub("LibInit"):NewAddon(ns,me,{noswitch=true,profile=true},"AceHook-3.0","AceEvent-3.0","AceTimer-3.0")
else
	addon=LibStub("LibInit"):NewAddon(me,"AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceBucket-3.0")
end
local pairs=pairs
local wipe=wipe
local C=addon:GetColorTable()
local L=addon:GetLocale()
local FishingId=131474
local Fishing=''
local FishingIcon=''
local FishingPole
local FishingPoleId=6256
local FishingPolesCategory
local pattern=format(ERR_SKILL_UP_SI,"Fishing","999"):gsub("999.","(%%d+)"):gsub("Fishing",".*")
local IsFishing
local CanFish
local NoPoleWarn=true
local start
local stop
local baits
local fishingName="Fishing"
local fishingTexture="Interface\\Icons\\Trade_Fishing"
local fishingSkillID
local fishingSkill=0
local fishingCap=0
local fishingBonus=0
local weapons
local warned
local function fade(delay)
		start.waitAndAnimOut:Stop();
		start.waitAndAnimOut.animOut:SetStartDelay(delay or 0.1);
		start.waitAndAnimOut:Play()
end
function addon:CHAT_MSG_SKILL(event,msg)
	local skill=msg:match(pattern)
	if skill then
		fishingSkill=skill
		if (fishingSkill and fishingSkillID) then
			local _
			fishingCap,_,_,_,fishingBonus=select(4,GetProfessionInfo(fishingSkillID))
			start.Amount:SetFormattedText(TRADESKILL_RANK_WITH_MODIFIER,fishingSkill,fishingBonus,fishingCap)
		end
	end
end
function addon:PLAYER_REGEN_ENABLED()
	if (not IsFishing) then
		self:NoFish()
	end
end
function addon:PLAYER_REGEN_DISABLED()
	local id=GetInventoryItemID("player",INVSLOT_MAINHAND)
	self:RestoreWeapons()
end
function addon:FISH_ENDED()
	self:FillBait()
	self:StartFishFrame(true)
end
function addon:FISH_STARTED()
	stop:Show()
end
function addon:COMBAT_LOG_EVENT_UNFILTERED(_,timestamp,event,hidecaster,sguid,sname,sflags,sraidflags,dguid,dname,dflags,dRaidflags,spellid,spellname,stack,kind,...)
	if (bit.band(COMBATLOG_OBJECT_AFFILIATION_MINE,dflags)==1) then
--@debug@
		print(event,sname,dname,spellid,'(',spellname,')',stack,kind,...)
--@end-debug@
		if (start and not InCombatLockdown()) then
			if (type(spellname)=="string" and spellname:find(Fishing)) then
				if (kind=="BUFF") then
					if (event == "SPELL_AURA_REMOVED") then
						self:FISH_ENDED()
					elseif (event == "SPELL_AURA_APPLIED") then
						self:FISH_STARTED()
					end
				end
			end
		end
	end
end
function addon:PLAYER_EQUIPMENT_CHANGED(event,slot,hasItem)
--@debug@
	print(event,slot,hasItem)
--@end-debug@
	if (slot==INVSLOT_MAINHAND or slot==INVSLOT_OFFHAND) then
		local ID=GetInventoryItemID("player",slot)
		if (ID) then
			if (select(7,GetItemInfo(ID))==FishingPolesCategory) then
				FishingPole=GetItemInfo(ID)
				if not IsFishing then self:Fish(IsFishing) end
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
		self:Print(format(L["Found %s"],maxname))
	end
	return maxname
end
function addon:Info(...)
	for k,v in pairs(weapons) do
	if (v) then
		self:Print(k,"=",v.name)
	end
	end
	if (FishingPole) then
		self:Print(format(L["Fishing pole is %s"],GetItemInfo(FishingPole)))
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
	--@debug@
	print("Storing weapons")
	--@end-debug@
	local id=GetInventoryItemID("player",INVSLOT_MAINHAND)
	if (id) then pushWeapon(weapons[INVSLOT_MAINHAND],GetItemInfo(id)) end
	id=GetInventoryItemID("player",INVSLOT_OFFHAND)
	if (id) then pushWeapon(weapons[INVSLOT_OFFHAND],GetItemInfo(id)) end
end
function addon:RestoreWeapons()
	if (weapons[INVSLOT_MAINHAND].name) then EquipItemByName(weapons[INVSLOT_MAINHAND].name) end
	if (weapons[INVSLOT_OFFHAND].name) then EquipItemByName(weapons[INVSLOT_OFFHAND].name) end
end

function addon:SKILL_LINES_CHANGED()
	if (not CanFish) then
		self:Discovery()
	end
end
function addon:Discovery()
	local _
	FishingPolesCategory=select(7,GetItemInfo(FishingPoleId))
	Fishing,_,FishingIcon=GetSpellInfo(FishingId)
	if (not FishingPolesCategory or not Fishing) then
--@debug@
		print("Rescheduled")
--@end-debug@
		self:ScheduleTimer("Discovery",0.5)
	else
--@debug@
		print("Init")
--@end-debug@
		self:Init()
	end
end

function addon:Init()
	self:StoreWeapons()
	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions()
	if (fishing) then
		CanFish = true
	end
	self:SetupFrames()
	if (CanFish) then
		fishingName,fishingTexture,fishingSkill,fishingCap=GetProfessionInfo(fishing)
		self:SetupFrames()
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("CHAT_MSG_SKILL")
		self:UnregisterEvent("SKILL_LINES_CHANGED")
		FishingPole=self:GetFishingPole()
	else
		if not warned then
			self:Print(L["You should learn to fish, if you installed me :)"])
			warned=true
		end
		self:NoFish()
	end
end

function addon:ShowAtMouse(frame)
	local scale=UIParent:GetScale()
	local x,y=GetCursorPosition()
	frame:ClearAllPoints()
	frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x/scale + 10/scale,y/scale)
	frame:Show()
	fade(2)
end
function addon:ShowAtCenter(frame,offset)
	offset=offset or 10
	frame:ClearAllPoints()
	frame:SetPoint("CENTER",UIParent,"CENTER",offset,0)
	frame:Show()
	fade(10)
end
function addon:StartFishFrame(atCursor)
	IsFishing=true
	if (atCursor) then
		self:ShowAtMouse(start)
	else
		self:EquipFishingPole()
		self:ShowAtCenter(start)
	end
	self:FillBait()
	baits:Show()
	stop:Show()
	fishingSkillID=select(4,GetProfessions())
	if (fishingSkillID) then
		local _
		fishingSkill,fishingCap,_,_,_,fishingBonus=select(3,GetProfessionInfo(fishingSkillID))
	end
	start.Amount:SetFormattedText(TRADESKILL_RANK_WITH_MODIFIER,fishingSkill,fishingBonus,fishingCap)
end
function addon:StopFishFrame(show)
	local body,main,off='/stopcasting',weapons[INVSLOT_MAINHAND].name,weapons[INVSLOT_OFFHAND].name
	if (main and off) then
			body=format("/stopcasting\n/equip %s\n/equip %s",main,off)
	elseif (main or off) then
			body=format("/stopcasting\n/equip %s",main or off)
	else
			body='/stopcasting'
	end
	body="/dump 'macro partita'\n" .. body
	stop:SetAttribute("type","macro");
	stop:SetAttribute("macrotext",body)
	if (show) then
		stop:Show()
	else
		stop:Hide()
	end
end
function addon:OnEnter(this)
--@debug@
	print(this)
--@end-debug@
end
function addon:OnAnimationStop(this,requested)
	if (not self:IsFishing()) then
		self:NoFish()
	end
end
local waitingframes={}
function addon:GET_ITEM_INFO_RECEIVED(event,itemID)
	local f=waitingframes[itemID]
	--@debug@
	print(event,itemID,f)
	--@end-debug@
	if f then
		waitingframes[itemID]=nil
		self:SetIcon(f)
	end
	for k,v in pairs(waitingframes) do
		if v then return end
	end
	wipe(waitingframes)
	--@debug@
	print("Removed GET ITEM hook")
	--@end-debug@
	self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
end
function addon:SetIcon(frame)
	local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(frame.itemID);
	if itemTexture then
		frame.Icon:SetTexture(itemTexture);
	else
		--@debug@
		print("Unable to retrieve info for ",frame.itemID)
		--@end-debug@
	end
end
function addon:FillBait()
	local baits=MrFishBaitFrame
	local n=0
	for i=1,#ns.baits do
		local itemID=ns.baits[i]
		local qt=GetItemCount(itemID)
		if qt and qt > 0 then
			n=n+1
			local bait=baits.baits[n]
			if (not bait) then
				bait=CreateFrame("Button",nil,baits,"MrFishBaitButton")
				baits.baits[n]=bait
			end
			bait:SetPoint("BOTTOMLEFT",baits,40*n-37,3)
			bait:SetSize(40,40)
			bait.Icon:SetSize(40,40)
			bait.itemID=itemID
			bait.Quantity:SetFormattedText("%d",GetItemCount(itemID))
			bait.Quantity:SetTextColor(C.Yellow())
			bait.Quantity:Show()
			bait:EnableMouse(true)
			bait:RegisterForClicks("LeftButtonDown","RightButtonDown")
			bait:SetAttribute("type*","item")
			bait:SetAttribute("item",select(2,GetItemInfo(itemID)))
			bait:SetScript("PostClick",function() self:ScheduleTimer("FillBait",5) end)
			self:SetIcon(bait)
			bait:Show()
		end
	end
	if n==0 then
		baits:Hide()
		return
	end
	for i=n+1,#baits.baits do
		baits.baits[i]:Hide()
	end
	baits:SetWidth(40*n+6)
	baits:SetHeight(65)
	local backdrop = {
			--bgFile="Interface\\TutorialFrame\\TutorialFrameBackground",
			bgFile="Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
			edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
			tile=true,
			tileSize=16,
			edgeSize=16,
			insets={bottom=2,left=2,right=2,top=2}
	}
	baits:SetBackdrop(backdrop)
end
function addon:SetupFrames()
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	start.Icon:SetTexture("Interface\\Icons\\Trade_Fishing")
	start.Label:SetText(Fishing)
	start.Amount:SetFormattedText("%d/%d",fishingSkill,fishingCap)
	start:SetAttribute("type1","macro")
	start:SetAttribute("macrotext","/stopcasting\n/equip " .. (FishingPole or '') .. "\n/cast " .. Fishing)
	start:SetAttribute("type2","macro")
	start:SetAttribute("macrotext2","/stopcasting\n/equip " .. (FishingPole or '') .. "\n/cast " .. Fishing)
	start:SetAttribute("shift-type1","macro")
	start:SetAttribute("shift-macrotext1","/stopcasting")
	start.waitAndAnimOut:SetScript("OnFinished",function(this,requested) addon:OnAnimationStop(this,requested) end)
	start:SetScript("PostClick",function(this)
		fade(2)
	end )
	stop:SetText(BINDING_NAME_STOPCASTING .. ": " .. Fishing )
	stop:SetWidth(stop:GetFontString():GetStringWidth()+20)
	stop:SetScript("PostClick",function(this)
		addon:NoFish()
	end
	)
	self:FillBait()
	self:StopFishFrame(false)

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
function addon:IsFishing()
	return "Interface\\Icons\\Trade_Fishing"== select(4,UnitChannelInfo("player"))
end

------------------------------------
-- Ldb stuff
ns.LMB = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283\124t" -- left mouse button
ns.RMB = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385\124t" -- right mouse button
ns.NMB = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:89:144:228:283\124t" -- no mouse button
local fakeLdb={
	type = "data source",
	label = me,
	text=Fishing,
	category = "Profession",
	icon="Interface\\Icons\\Trade_Fishing",
	iconR=1,
	iconG=1,
	iconB=1,
}
local LDB=LibStub:GetLibrary("LibDataBroker-1.1",true)
local ldb= LDB:NewDataObject(me,fakeLdb) --#ldb
local icon = LibStub("LibDBIcon-1.0",true)
local KEY_BUTTON1=ns.LMB
local KEY_BUTTON2=ns.RMB
-- ldb extension
local oldIsFishing
function ldb:Update()
	ldb.text=IsFishing and C(Fishing,"GREEN") or C(Fishing,"SILVER")
end
function ldb:OnClick(button)
	if button=="RightButton" then
		addon:Gui()
		return
	else
		if IsFishing then addon:NoFish() else addon:Fish(false) end
	end

end
function ldb:OnTooltipShow(...)
	self:AddLine("MrFish")
	self:AddDoubleLine(KEY_BUTTON1,L['Fishing mode on/off'],nil,nil,nil,C:Green())
	self:AddDoubleLine(KEY_BUTTON2,L['Open configuration'],nil,nil,nil,C:Green())

end
function addon:SetDbDefaults(default)
	default.char.weapons={
		[INVSLOT_MAINHAND]={},
		[INVSLOT_OFFHAND]={},
	}
end
function addon:OnInitialized()
	ldb:Update()
	weapons=self.db.char.weapons
	self:RestoreWeapons()
	start=MrFishButton
	stop=MrFishStopButton
	baits=MrFishBaitFrame
	self:AddBoolean("MINIMAP",false,L["Hide minimap icon"],L["If you hide minimap icon, use /mac gui to access configuration and /mac requests to open requests panel"])
	self:AddToggle("RESTORE",true,L["Restore weapons on logout"],L["Always attempts to restore weapon on logout"])
	self:AddChatCmd("Fish","fish")
	self:AddChatCmd("NoFish","nofish")
	self:AddPrivateOpenCmd("info","Info")
	self:RegisterEvent("SKILL_LINES_CHANGED")
	self:Discovery()
	if icon then
		icon:Register(me,ldb,self.db.profile.ldb)
	end
	return true
end
function addon:ApplyMINIMAP(value)
	if value then
		icon:Hide(me)
	else
		icon:Show(me)
	end
	self.db.profile.ldb={hide=value}
end
function addon:ApplyRESTORE(value)
	if (true) then
		self:RegisterEvent("PLAYER_LOGOUT","RestoreWeapons")
	else
		self:UnregisterEvent("PLAYER_LOGOUT")
	end
end
function addon:Fish(atCursor)
	IsFishing=true
	if (not self:IsFishing()) then
		self:EquipFishingPole()
	end
	self:StartFishFrame(atCursor)
	ldb:Update()
end
function addon:NoFish()
	self:OnLeaveCombat("RestoreWeapons")
	start:Hide()
	stop:Hide()
	baits:Hide()
	IsFishing=false
	ldb:Update()
end
_G.MrFish=addon

