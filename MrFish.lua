local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- MUST BE LINE 1
local _,_,_,toc=GetBuildInfo()
local pp=print
local me, ns = ...
--@debug@
print("Loading",__FILE__," inside ",me)
--@end-debug@
if (LibDebug) then LibDebug() end
local function debug(...)
	--@debug@
	print(...)
	--@end-debug@
end
local print=_G.print
local notify=_G.print
local error=_G.error
local sdebug=debug
local function dump() end
local function debugEnable() end
if (LibStub("AlarLoader-3.0",true)) then
	local rc=LibStub("AlarLoader-3.0"):GetPrintFunctions(me)
	print=rc.print
	--@debug@
	debug=rc.debug
	sdebug=rc.sdebug
	dump=rc.dump
	--@end-debug@
	notify=rc.notify
	error=rc.error
	debugEnable=rc.debugEnable
else
	debug("Missing AlarLoader-3.0")
end
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local C=LibStub("AlarCrayon-3.0"):GetColorTable()
-----------------------------------------------------------------
local addon=LibStub("AlarLoader-3.0"):CreateAddon(me,true) --#MrFish
function addon:OnInitialized()
	self:loadHelp()
	return true
end