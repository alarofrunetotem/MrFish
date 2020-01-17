local me,ns=...
local L=LibStub("AceLocale-3.0"):GetLocale(me,true)
local hlp=LibStub("AceAddon-3.0"):GetAddon(me)
function hlp:loadHelp()
self:HF_Title("Mr Fish","RELNOTES")
self:HF_Paragraph("Description")
self:HF_Pre([[
Mr Fish manages your fishing needs giving you a quick line cast button and automagically switching eq.
It even changes back to weapons if you enter combat

/fish
Starts fishing

/nofish
Stops fishing

]])
self:RelNotes(2,4,5,[[
Toc: 8.3.0
]])
self:RelNotes(2,4,4,[[
Feature: Updated for 8.2
]])
self:RelNotes(2,4,3,[[
Fix: now uses new itembutton instead of itembuttontemplate
]])
self:RelNotes(2,4,0,[[
Thanks to fuba
Fix: Fixed Weapon Swap when entering Combat in Fishing
Fix: Fixed wrong Weapon/Offand Equiped after stop Fishing
Fix: MrFish will now be disabled when entering Combat
You need enable it manually after Combat again
Fix: Changed to use ItemLink instead of ItemID to Store and Restore Weapons because of Enchants and Sockets
Example: This will prevent to equip the Wrong Item with the same Name but different Itemlevel, Enchant or Socket(s)
Fix: Added a Delay of 0.5 Seconds before the Fishing Button appears
  So the Bonus will now shown correctly after equip a Fishing Pole
]])
self:RelNotes(2,3,0,[[
Feature: fisihing button is now less invasive
]])

self:RelNotes(2,2,2,[[
Fix: Version number is now the expected one
Fix: lua error when starting
Feature: you can reequip weapons and exit fishing mode just walking for more than 3 seconds
]])
self:RelNotes(1,2,1,[[
Feature: attempt to be smarter.Tries to keep fish button visible while you add a lure or move to a better spot
]])
self:RelNotes(1,1,1,[[
Fix:removed an old debug message
]])
self:RelNotes(1,0,1,[[
Feature; Portoguese localization
Fix: fixes a possile crash
]])
self:RelNotes(1,0,0,[[
Initial release
]])

end

