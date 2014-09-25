local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:RelNotes(1,0,0,[[
Initial release
]])
self:HF_Title("Mr Fish","Description")
self:HF_Paragraph("Description")
self:HF_Pre([[
Mr Fish manages your fishing needs giving you a quick line cast button and automagically switching eq.
It even changes back to weapons if you enter combat

/fish
Switch your weapons with a fishing pole and displays a detached button to cast your line.
You then click to cast (you can keep clicking untili your line doesnt land in a fishing pole).
When you take your fish, MrFish display again the button at your mouse, ready to be recasted without hand motion.
It even accepts right click to avoid finger change on mouse

/nofish
Removes the fishing button and reequips your weapons

]])
end

