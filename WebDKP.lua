-- Sandstens fork
SandstensForkVersion = "Version 2017-11-03"
AutoInvitePlayersKronos = {"Sandsten","Bernsten","Smygsten","Stenskott","Bergsten","Kylsten","Gravsten","Eldsten","Eldstina","Sandybank","Kalven","Ibanezer","Trairg","Arkemea","Tentto","Leshaniqua","Gruuz","Looz","Drooz","Larona","Pricey","Myname","Orthoron","Valkoron","Thralloron","Kalvoron","Kimono","Awsomenews","Evilmojo","Hurmelhej","Cadux","Cadex","Roxigar","Hellcow","Nakz","Kruzz","Fellsten","Filon","Delthar"}
AutoInviteGuildRanks = { "Class Leader","Officer","Officer Alt"}
--
--
------------------------------------------------------------------------
-- WEB DKP
------------------------------------------------------------------------
-- An addon to help manage the dkp for a guild. The addon provides a 
-- list of the dkp of all players as well as an interface to add / deduct dkp 
-- points. 
-- The addon generates a log file which can then be uploaded to a companion 
-- website at www.webdkp.com
--
--
-- HOW THIS ADDON IS ORGANIZED:
-- The addon is grouped into a series of files which hold code for certain
-- functions. 
-- 
-- WebDKP			Code to handle start / shutdown / registering events
--					and GUI event handlers. This is the main entry point
--					of the addon and directs events to the functionality
--					in the other files
--
-- GroupFunctions	Methods the handle scanning the current group, updating
--					the dkp table to be show based on filters, sorting, 
--					and updating the gui with the current table
--
-- Announcements	Code handling announcements as they are echoed to the screen
--
-- WhisperDKP		Implementation of the Whisper DKP feature. 
--
-- Utility			Utility and helper methods. For example, methods
--					to find out a users guild or print something to the 
--					screen. 

-- AutoFill			Methods related to autofilling in item names when drops
--					Occur		
------------------------------------------------------------------------

---------------------------------------------------
-- MEMBER VARIABLES
---------------------------------------------------
-- Sets the range of dkp that defines tiers.
-- Example, 50 would be:
-- 0-50 = teir 0
-- 51-100 = teir 1, etc
WebDKP_TierInterval = 50;   

-- Specify what filters are turned on and off. 1 = on, 0 = off
-- (Don't mess around with)
WebDKP_Filters = {
	["Druid"] = 1,
	["Hunter"] = 1,
	["Mage"] = 1,
	["Rogue"] = 1,
	["Shaman"] = 1,
	["Paladin"] = 1,
	["Priest"] = 1,
	["Warrior"] = 1,
	["Warlock"] = 1,
	["Group"] = 1
}

-- The dkp table itself (This is loaded from the saved variables file)
-- Its structure is:
-- ["playerName"] = {
--		["dkp"] = 100,
--		["class"] = "ClassName",
--		["Selected"] = true/ false if they are selected in the guid
-- }
WebDKP_DkpTable = {};
WebDKP_BenchTable = {}; -- Not in use ?

WebDKP_BenchList = {};
WebDKP_Bench_TotalToday = 0;

-- Holds the list of users tables on the site. This is used for those guilds
-- who have multiple dkp tables for 1 guild. 
-- When there are multiple table names in this list a drop down will appear 
-- in the addon so a user can select which table they want to award dkp to
-- Its structure is: 
-- ["tableName"] = { 
--		["id"] = 1 (this is the tableid of the table on the webdkp site)
-- }
WebDKP_Tables = {};
selectedTableid = 1;


-- The dkp table that will be shown. This is filled programmatically
-- based on running through the big dkp table applying the selected filters
WebDKP_DkpTableToShow = {}; 

-- Keeps track of the current players in the group. This is filled programmatically
-- and is filled with Raid data if the player is in a raid, or party data if the
-- player is in a party. It is used to apply the 'Group' filter
WebDKP_PlayersInGroup = {};

-- Keeps track of the sorting options. 
-- Curr = current columen being sorted
-- Way = asc or desc order. 0 = desc. 1 = asc
WebDKP_LogSort = {
	["curr"] = 3,
	["way"] = 1 -- Desc
};

-- Additional user options
WebDKP_Options = {
	["AutofillEnabled"] = 1,		-- auto fill data. 0 = disabled. 1 = enabled. 
	["AutofillThreshold"] = 2,		-- What level of items should be picked up by auto fill. -1 = Gray, 4 = Orange
	["AutoAwardEnabled"] = 1,		-- Whether dkp awards should be recorded automatically if all data can be auto filled (user is still prompted)
	["SelectedTableId"] = 1,		-- The last table that was being looked at
	["MiniMapButtonAngle"] = 1,
}

-- User options that are syncronized with the website
WebDKP_WebOptions = {			
	["ZeroSumEnabled"] = 0,			-- Whether or not to use ZeroSum DKP settings
}

-- Lists of the different bosses
function Set (list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

MC = Set {"Lucifron", "Magmadar", "Gehennas",
        "Garr", "Baron Geddon", "Shazzrah", "Sulfuron Harbinger", 
        "Golemagg the Incinerator", "Majordomo Executus", "Ragnaros"}

BWL = Set {"Razorgore the Untamed", "Vaelastrasz the Corrupt", "Broodlord Lashlayer",
        "Firemaw", "Ebonroc", "Flamegor", "Chromaggus", 
        "Nefarian"}

AQ = Set {"The Prophet Skeram", "Battleguard Sartura", "Fankriss the Unyielding",
        "Princess Huhuran", "Vek'lor", "Vek'nilash", "C'Thun", 
        "Yauj", "Vem", "Kri", "Viscidus", "Ouro"}

NAXX = Set {"Anub'Rekhan", "Grand Widow Faerlina", "Maexxna",
        "Noth the Plaguebringer", "Heigan the Unclean", "Loatheb", 
        "Instructor Razuvious", "Gothik the Harvester", "The Four Horsemen",
        "Patchwerk", "Grobbulus", "Gluth", "Thaddius",
    	"Sapphiron", "Kel'Thuzad"}

BossLocation = Set {"Durotar", "The Molten Core", "Blackwing Lair", "Onyxia's Lair", "Ahn'Qiraj", "Temple of Ahn'Qiraj", "Naxxramas", "The Arachnid Quarter", "The Plague Quarter", "The Military Quarter", "The Construct Quarter", "Frostwyrm Lair"}


---------------------------------------------------
-- INITILIZATION
---------------------------------------------------
-- ================================
-- On load setup the slash event to will toggle the gui
-- and register for some events
-- ================================
function WebDKP_OnLoad()
	SlashCmdList["WEBDKP"] = WebDKP_ToggleGUI;
	SLASH_WEBDKP1 = "/webdkp";
	SlashCmdList["BID"] = WebDKP_Bid_ToggleUI;
	SLASH_BID1 = "/bid";	
	SlashCmdList["BENCH"] = WebDKP_Bench_ToggleUI;
	SLASH_BENCH1 = "/bench";
	SlashCmdList["BOSSKILL"] = WebDKP_Bosskill;
	SLASH_BOSSKILL1 = "/bosskill";
	SlashCmdList["HOUR"] = WebDKP_AddHourly;
	SLASH_HOUR1 = "/hour";
	SlashCmdList["EARLY"] = WebDKP_AddEarly;
	SLASH_EARLY1 = "/early";

	--SlashCmdList["TEST"] = WebDKP_Test;
	--SLASH_TEST1 = "/test";
	
		
	-- Register for party / raid changes so we know to update the list of players in group
	this:RegisterEvent("PARTY_MEMBERS_CHANGED"); 
	this:RegisterEvent("RAID_ROSTER_UPDATE"); 
	this:RegisterEvent("CHAT_MSG_WHISPER"); 
	this:RegisterEvent("ITEM_TEXT_READY");
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("CHAT_MSG_LOOT");
	this:RegisterEvent("CHAT_MSG_PARTY");
	this:RegisterEvent("CHAT_MSG_RAID");
	this:RegisterEvent("CHAT_MSG_RAID_LEADER");
	this:RegisterEvent("CHAT_MSG_RAID_WARNING");
	this:RegisterEvent("ADDON_ACTION_FORBIDDEN");
	this:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH");
	
	WebDKP_OnEnable();
	
	
	
end

-- ================================
-- Called when the addon is enabled. 
-- Takes care of basic startup tasks: hide certain forms, 
-- get the people currently in the group, register for events, 
-- etc. 
-- ================================
function WebDKP_OnEnable()
	WebDKP_Frame:Hide();
	getglobal("WebDKP_FiltersFrame"):Show();
	getglobal("WebDKP_AwardDKP_Frame"):Hide();
	getglobal("WebDKP_AwardItem_Frame"):Hide();
	getglobal("WebDKP_Options_Frame"):Hide();
	
	WebDKP_UpdatePlayersInGroup();
	WebDKP_UpdateTableToShow();
	
	-- place a hook on the chat frame so we can filter out our whispers
	WebDKP_Register_WhisperHook();
	
	-- place a hook on item shift+clicks so we can get item details
		-- for links in chat
	WebDKP_Register_ShiftClickLinkHook();
		-- for blizzard loot window
	WebDKP_Register_ShiftClickLootWindowHook();	
	-- start auto-inv program
	auto_inv();

end


function WebDKP_Register_ShiftClickLinkHook()
	--== For links in chat ==-

	local oldClick = ChatFrame1:GetScript("OnHyperlinkClick")
	ChatFrame1:SetScript("OnHyperlinkClick", function() 
		if ( IsShiftKeyDown() and WebDKP_BidFrame:IsShown() ) then
			WebDKP_ItemChatClick(arg1, arg2) --itemString, itemLink
		end
		oldClick() 
	end)
end

function WebDKP_Register_ShiftClickLootWindowHook()
	--== For blizzard loot window ==--
	for i = 1, 4 do 
		local oldClick = getglobal("LootButton"..i):GetScript("OnClick")
		getglobal("LootButton"..i):SetScript("OnClick", function() 
	        if ( IsShiftKeyDown() ) then 
	            WebDKP_Bid_ShowUI()
	            for i = 1, 4 do
	            	if string.find(this:GetName(), i) then
	            		_, itemName, _, _, _ = GetLootSlotInfo(i)
	            		itemLink = GetLootSlotLink(i)
	         			WebDKP_ItemChatClick(itemName, itemLink);
	         		end
	     		end
	        end
	        oldClick()
		end)
	end
end

function WebDKP_Register_ShiftClickLootWindowHook_xloot()
	--== This function is run from XLoot.lua:555 when button is onClick ==--
	if ( IsShiftKeyDown() ) then 
	    WebDKP_Bid_ShowUI()
	    for i = 1, GetNumLootItems() do
	    	if string.find(this:GetName(), i) then
	    		_, itemName, _, _, _ = GetLootSlotInfo(i)
	    		itemLink = GetLootSlotLink(i)
	 			WebDKP_ItemChatClick(itemName, itemLink);
	 		end
		end
	end
	xLootOldClick()
end


------TESTING-------------------
function WebDKP_Test()
	test_roster()
	--auto_inv()
	DEFAULT_CHAT_FRAME:AddMessage(GetZoneText());
end

--[[
function auto_inv()
	local f = CreateFrame("frame")
	f:RegisterEvent("CHAT_MSG_WHISPER")
	f:SetScript("OnEvent", function()
    	if ( not UnitExists("party1") or IsPartyLeader("player")) and arg1 == "kamelåså"  then
        	InviteByName(arg2)
 	  	end
	end)
end]]

function auto_inv()
	local f = CreateFrame("frame")
	f:RegisterEvent("CHAT_MSG_WHISPER")
	f:SetScript("OnEvent", function()
		if(arg1 == "+") then
			if UnitInRaid("player") then
				
				local skipnext = false
				--Kronos auto invite
				if GetRealmName() == "Kronos" then
					for i=1,getn(AutoInvitePlayersKronos) do
						if (arg2==AutoInvitePlayersKronos[i]) then
							InviteByName(arg2)
							PromoteToAssistant(arg2)
							skipnext = true
						end
					end
				end
				
				--Auto invite guild members with ranks 
				if skipnext == false then
					for i = 1, GetNumGuildMembers() do
						local name, rank, rankIndex, level, _, _, _, _, online = GetGuildRosterInfo(i)
						if online and name == arg2 then
						
							for i=1,getn(AutoInviteGuildRanks) do
								if (rank==AutoInviteGuildRanks[i]) then
									InviteByName(arg2)
									PromoteToAssistant(arg2)
								end
							end
								
						end
					end
				end
				
			end
		end
	end)
end

function string:split(delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( self, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( self, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( self, delimiter, from  )
  end
  table.insert( result, string.sub( self, from  ) )
  return result
end

--Sandsten giveout decay to all
function WebDKP_GiveoutDecayDialogBox_ToggleUI()
	StaticPopupDialogs["GIVEOUT_DKP_TO_ALL_PROMPT"] = {
		text = "How much decay do you want to subtract?\n\nThis will subtract from EVERY player.\n If this results in negative DKP the players total will be set to zero.",
	  	button1 = "Confirm",
	  	button2 = "Cancel",
		
		OnShow = function()
			getglobal(this:GetName().."EditBox"):SetFocus()
			getglobal(this:GetName().."EditBox"):SetText("45")
			getglobal(this:GetName().."EditBox"):HighlightText()
		end,
		
	  	OnAccept = function()
			local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
			if text ~= "" then
				-- Do Decay before clearing bench aka total dkp today
				WebDKP_GiveOutDecayToAll(text)
				-- Set all players with negative DKP to 0 
				WebDKP_FixNegative()
			end
	  	end,
	  	timeout = 0,
	  	hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("GIVEOUT_DKP_TO_ALL_PROMPT")
end

--Sandsten giveout decay percentage to all
function WebDKP_GiveoutDecayPercentageDialogBox_ToggleUI()
	StaticPopupDialogs["GIVEOUT_DKP_PERCENTAGE_TO_ALL_PROMPT"] = {
		text = "How much percentage (rounded up) do you want to subtract?\n\nThis will subtract from EVERY player.",
	  	button1 = "Confirm",
	  	button2 = "Cancel",
		
		OnShow = function()
			getglobal(this:GetName().."EditBox"):SetFocus()
			getglobal(this:GetName().."EditBox"):SetText("10")
			getglobal(this:GetName().."EditBox"):HighlightText()
		end,
		
	  	OnAccept = function()
			local text = getglobal(this:GetParent():GetName().."EditBox"):GetText()
			if text ~= "" then
				-- Do Decay before clearing bench aka total dkp today
				WebDKP_GiveOutDecayPercentageToAll(text)
				-- Set all players with negative DKP to 0 
				WebDKP_FixNegative()
			end
	  	end,
	  	timeout = 0,
	  	hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("GIVEOUT_DKP_PERCENTAGE_TO_ALL_PROMPT")
end

function WebDKP_Bosskill()
	StaticPopupDialogs["HANDOUT_BOSSDKP_PROMPT"] = {
		text = "Do you want to award 5 dkp for boss?",
	  	button1 = "Yes",
	  	button2 = "No",
		--OnShow = function ()
		--    getglobal(this:GetName().."EditBox"):SetText("");
		--end,
	  	OnAccept = function()
	  		--local text_editbox = getglobal(this:GetParent():GetName().."EditBox"):GetText();
	      	WebDKP_Bosskill_Add_DKP("boss")
	      	--DEFAULT_CHAT_FRAME:AddMessage("test, ADDING MANUALLY DKP 5 all raid! yey"..text_editbox)
	  	end,
	  	timeout = 0,
	  	--hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("HANDOUT_BOSSDKP_PROMPT")
end

function WebDKP_AddHourly()
	StaticPopupDialogs["HANDOUT_HOURLY_PROMPT"] = {
		text = "Do you want to award 5 dkp (hourly dkp)?",
	  	button1 = "Yes",
	  	button2 = "No",
	  	OnAccept = function()
	  		--local text_editbox = getglobal(this:GetParent():GetName().."EditBox"):GetText();
	      	WebDKP_Bosskill_Add_DKP("hourly")
	      	--DEFAULT_CHAT_FRAME:AddMessage("test, ADDING MANUALLY DKP 5 all raid! yey"..text_editbox)
	  	end,
	  	timeout = 0,
	  	--hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("HANDOUT_HOURLY_PROMPT")
end

function WebDKP_AddEarly()
	StaticPopupDialogs["HANDOUT_EARLY_PROMPT"] = {
		text = "Do you want to award 10 dkp (early dkp)?",
	  	button1 = "Yes",
	  	button2 = "No",
	  	OnAccept = function()
	  		--local text_editbox = getglobal(this:GetParent():GetName().."EditBox"):GetText();
	  		local reason = "early";
	      	WebDKP_Bosskill_Add_DKP(reason)
	      	--DEFAULT_CHAT_FRAME:AddMessage("test, ADDING MANUALLY DKP 5 all raid! yey"..text_editbox)
	  	end,
	  	timeout = 0,
	  	--hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("HANDOUT_EARLY_PROMPT")
end

function WebDKP_Bosskill_Event()
	if(WebDKP_Options["WebDKP_Enabled"]) then
		--if IsPartyLeader("player") then
			local zoneName = GetZoneText();

			-- Getting killed boss name --
			local name = ""
			local list = string.split(arg1, " dies.")
			if (list) then
				name = list[1]
			end

			if BossLocation[zoneName] then
				if (MC[name] or BWL[name] or name == "Onyxia" or AQ[name] or NAXX[name])then
					WebDKP_Bosskill_Add_DKP();
					--WebDKP_Bench_Add_DKP();
					--DEFAULT_CHAT_FRAME:AddMessage("test, ADDING DKP 5 all raid! yey")
				end
			end
		--end
	end
end



-- ================================
-- Invoked when we recieve one of the requested events. 
-- Directs that event to the appropriate part of the addon
-- ================================
function WebDKP_OnEvent()
	--DEFAULT_CHAT_FRAME:AddMessage(event);
	if(event=="CHAT_MSG_WHISPER") then
		WebDKP_CHAT_MSG_WHISPER();
	elseif(event=="CHAT_MSG_PARTY" or event=="CHAT_MSG_RAID" or event=="CHAT_MSG_RAID_LEADER" or event=="CHAT_MSG_RAID_WARNING") then
		WebDKP_CHAT_MSG_PARTY_RAID();
	elseif(event=="PARTY_MEMBERS_CHANGED") then
		WebDKP_PARTY_MEMBERS_CHANGED();
	elseif(event=="RAID_ROSTER_UPDATE") then
		WebDKP_RAID_ROSTER_UPDATE();
	elseif(event=="ADDON_LOADED") then
		WebDKP_ADDON_LOADED();
	elseif(event=="CHAT_MSG_LOOT") then
		WebDKP_Loot_Taken();
	elseif(event=="ADDON_ACTION_FORBIDDEN") then
		WebDKP_Print(arg1.."  "..arg2);
	elseif(event=="CHAT_MSG_COMBAT_HOSTILE_DEATH") then
		WebDKP_Bosskill_Event();
	end
end

-- ================================
-- Invoked when addon finishes loading data from the saved variables file. 
-- Should parse the players options and update the gui.
-- ================================
function WebDKP_ADDON_LOADED()
	if( WebDKP_DkpTable == nil) then
		WebDKP_DkpTable = {};
	end
	if( WebDKP_Options == nil ) then
		WebDKP_Options = {};
	end
	if( WebDKP_WebOptions == nil ) then
		WebDKP_WebOptions = {};
	end

	--load up the last loot table that was being viewed
	WebDKP_Frame.selectedTableid = WebDKP_Options["SelectedTableId"];
	--WebDKP_Options_Autofill_DropDown_Init();
	
	-- load the options from saved variables and update the settings on the 
	if ( WebDKP_Options["AutofillEnabled"] == 1 ) then
		WebDKP_Options_FrameToggleAutofill:SetChecked(1);
		WebDKP_Options_FrameAutofillDropDown:Show();
		WebDKP_Options_FrameToggleAutoAward:Show();
	else
		WebDKP_Options_FrameToggleAutofill:SetChecked(0);
		WebDKP_Options_FrameAutofillDropDown:Hide();
		WebDKP_Options_FrameToggleAutoAward:Hide();
	end 
	
	WebDKP_Options_FrameToggleAutoAward:SetChecked(WebDKP_Options["AutoAwardEnabled"]);
	WebDKP_Options_FrameToggleZeroSum:SetChecked(WebDKP_WebOptions["ZeroSumEnabled"]);
	
	WebDKP_UpdateTableToShow(); --update who is in the table
	WebDKP_UpdateTable();       --update the gui
	
	-- set the mini map position
	WebDKP_MinimapButton_SetPositionAngle(WebDKP_Options["MiniMapButtonAngle"]);
	
	-- set enabled option
	if(WebDKP_Options["WebDKP_Enabled"]) then
		WebDKP_MinimapButton:SetNormalTexture("Interface\\AddOns\\WebDKP\\\Textures\\MinimapButton")
	else
		WebDKP_MinimapButton:SetNormalTexture("Interface\\AddOns\\WebDKP\\\Textures\\MinimapButton_disabled")
	end
	
end


-- ================================
-- Called on shutdown. Does nothing
-- ================================
function WebDKP_OnDisable()
    
end


---------------------------------------------------
-- EVENT HANDLERS (Party changed / gui toggled / etc.)
---------------------------------------------------

-- ================================
-- Called by slash command. Toggles gui. 
-- ================================
function WebDKP_ToggleGUI()
	-- self:Print("Should toggle gui now...")
	-- WebDKP_Refresh()
	if ( WebDKP_Frame:IsShown() ) then
		WebDKP_Frame:Hide();
	else
		WebDKP_Frame:Show();	
		WebDKP_Tables_DropDown_OnLoad();
		WebDKP_Options_Autofill_DropDown_OnLoad();
		WebDKP_Options_Autofill_DropDown_Init();
	end
	
end

-- ================================
-- Handles the master loot list being opened 
-- ================================
function WebDKP_OPEN_MASTER_LOOT_LIST()
    
end

-- ================================
-- Called when the party / raid configuration changes. 
-- Causes the list of current group memebers to be refreshed
-- so that filters will be ok
-- ================================
function WebDKP_PARTY_MEMBERS_CHANGED()
	-- self:Print("Party / Raid change");
	WebDKP_UpdatePlayersInGroup();
	WebDKP_UpdateTableToShow();
	WebDKP_UpdateTable();
end
function WebDKP_RAID_ROSTER_UPDATE()
	-- self:Print("Party / Raid change");
	local newPlayer = WebDKP_UpdatePlayersInGroup_PlayerJoined();
	if(newPlayer ~= "") then
		WebDKP_Bench_AwardIfBench(newPlayer);
	end
	WebDKP_UpdatePlayersInGroup();
	WebDKP_UpdateTableToShow();
	WebDKP_UpdateTable();
end

-- ================================
-- Handles an incoming whisper. Directs it to the modules
-- who are interested in it. 
-- ================================
function WebDKP_CHAT_MSG_WHISPER()
	WebDKP_WhisperDKP_Event();
	WebDKP_Bid_Event();
	WebDKP_Bench_Event();
end

-- ================================
-- Event handler for all party and raid
-- chat messages. 
-- ================================
function WebDKP_CHAT_MSG_PARTY_RAID()
	WebDKP_Bid_Event();
end

---------------------------------------------------
-- GUI EVENT HANDLERS
-- (Handle events raised by the gui and direct
--  events to the other parts of the addon)
---------------------------------------------------
-- ================================
-- Called by the refresh button. Refreshes the people displayed 
-- in your party. 
-- ================================
function WebDKP_Refresh()
	WebDKP_UpdatePlayersInGroup();
	WebDKP_UpdateTableToShow();
	WebDKP_UpdateTable();
end

-- ================================
-- Called when a player clicks on different tabs. 
-- Causes certain frames to be hidden and the appropriate
-- frame to be displayed
-- ================================
function WebDKP_Tab_OnClick()
	if ( this:GetID() == 1 ) then
		getglobal("WebDKP_FiltersFrame"):Show();
		getglobal("WebDKP_AwardDKP_Frame"):Hide();
		getglobal("WebDKP_AwardItem_Frame"):Hide();
		getglobal("WebDKP_Options_Frame"):Hide();
	elseif ( this:GetID() == 2 ) then
		getglobal("WebDKP_FiltersFrame"):Hide();
		getglobal("WebDKP_AwardDKP_Frame"):Show();
		getglobal("WebDKP_AwardItem_Frame"):Hide();
		getglobal("WebDKP_Options_Frame"):Hide();
	elseif (this:GetID() == 3 ) then
		getglobal("WebDKP_FiltersFrame"):Hide();
		getglobal("WebDKP_AwardDKP_Frame"):Hide();
		getglobal("WebDKP_AwardItem_Frame"):Show();
		getglobal("WebDKP_Options_Frame"):Hide();
	elseif (this:GetID() == 4 ) then
		getglobal("WebDKP_FiltersFrame"):Hide();
		getglobal("WebDKP_AwardDKP_Frame"):Hide();
		getglobal("WebDKP_AwardItem_Frame"):Hide();
		getglobal("WebDKP_Options_Frame"):Show();
	end 
	PlaySound("igCharacterInfoTab");
end

-- ================================
-- Called when a player clicks on a column header on the table
-- Changes the sorting options / asc&desc. 
-- Causes the table display to be refreshed afterwards
-- to player instantly sees changes
-- ================================
function WebDPK2_SortBy(id)
	if ( WebDKP_LogSort["curr"] == id ) then
		WebDKP_LogSort["way"] = abs(WebDKP_LogSort["way"]-1);
	else
		WebDKP_LogSort["curr"] = id;
		if( id == 1) then
			WebDKP_LogSort["way"] = 0;
		elseif ( id == 2 ) then
			WebDKP_LogSort["way"] = 0;
		elseif ( id == 3 ) then
			WebDKP_LogSort["way"] = 1; --columns with numbers need to be sorted different first in order to get DESC right
		else
			WebDKP_LogSort["way"] = 1; --columns with numbers need to be sorted different first in order to get DESC right
		end
		
	end
	-- update table so we can see sorting changes
	WebDKP_UpdateTable();
end

-- ================================
-- Called when the user clicks on a filter checkbox. 
-- Changes the filter setting and updates table
-- ================================
function WebDKP_ToggleFilter(filterName)
	WebDKP_Filters[filterName] = abs(WebDKP_Filters[filterName]-1);
	WebDKP_UpdateTableToShow();
	WebDKP_UpdateTable();
end

-- ================================
-- Called when user clicks on 'check all'
-- Sets all filters to on and updates table display
-- ================================
function WebDKP_CheckAllFilters()
	WebDKP_SetFilterState("Druid",1);
	WebDKP_SetFilterState("Hunter",1);
	WebDKP_SetFilterState("Mage",1);
	WebDKP_SetFilterState("Rogue",1);
	WebDKP_SetFilterState("Shaman",1);
	WebDKP_SetFilterState("Paladin",1);
	WebDKP_SetFilterState("Priest",1);
	WebDKP_SetFilterState("Warrior",1);
	WebDKP_SetFilterState("Warlock",1);
	WebDKP_UpdateTableToShow();
	WebDKP_UpdateTable();
end

-- ================================
-- Called when user clicks on 'uncheck all'
-- Sets all filters to off and updates table display
-- ================================
function WebDKP_UncheckAllFilters()
	WebDKP_SetFilterState("Druid",0);
	WebDKP_SetFilterState("Hunter",0);
	WebDKP_SetFilterState("Mage",0);
	WebDKP_SetFilterState("Rogue",0);
	WebDKP_SetFilterState("Shaman",0);
	WebDKP_SetFilterState("Paladin",0);
	WebDKP_SetFilterState("Priest",0);
	WebDKP_SetFilterState("Warrior",0);
	WebDKP_SetFilterState("Warlock",0);
	WebDKP_UpdateTableToShow();
	WebDKP_UpdateTable();
end

-- ================================
-- Small helper method for filters - updates
-- checkbox state and updates filter setting in data structure
-- ================================
function WebDKP_SetFilterState(filter,newState)
	local checkBox = getglobal("WebDKP_FiltersFrameClass"..filter);
	checkBox:SetChecked(newState);
	WebDKP_Filters[filter] = newState;
end

-- ================================
-- Called when mouse goes over a dkp line entry. 
-- If that player is not selected causes that row
-- to become 'highlighted'
-- ================================
function WebDKP_HandleMouseOver()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	if( not WebDKP_DkpTable[playerName]["Selected"] ) then
		getglobal(this:GetName() .. "Background"):SetVertexColor(0.2, 0.2, 0.7, 0.5);
	end
end

function WebDKP_Bench_HandleMouseOver()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	if( not WebDKP_BenchTable[playerName]["Selected"] ) then
		getglobal(this:GetName() .. "Background"):SetVertexColor(0.2, 0.2, 0.7, 0.5);
	end
end

-- ================================
-- Called when a mouse leaes a dkp line entry. 
-- If that player is not selected, causes that row
-- to return to normal (none highlighted)
-- ================================
function WebDKP_HandleMouseLeave()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	if( not WebDKP_DkpTable[playerName]["Selected"] ) then
		getglobal(this:GetName() .. "Background"):SetVertexColor(0, 0, 0, 0);
	end
end

function WebDKP_Bench_HandleMouseLeave()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	if( not WebDKP_BenchTable[playerName]["Selected"] ) then
		getglobal(this:GetName() .. "Background"):SetVertexColor(0, 0, 0, 0);
	end
end

-- ================================
-- Called when the user clicks on a player entry. Causes 
-- that entry to either become selected or normal
-- and updates the dkp table with the change
-- ================================
function WebDKP_SelectPlayerToggle()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	if( WebDKP_DkpTable[playerName]["Selected"] ) then
		WebDKP_DkpTable[playerName]["Selected"] = false;
		getglobal(this:GetName() .. "Background"):SetVertexColor(0.2, 0.2, 0.7, 0.5);
	else
		WebDKP_DkpTable[playerName]["Selected"] = true;
		getglobal(this:GetName() .. "Background"):SetVertexColor(0.1, 0.1, 0.9, 0.8);
	end
end

--function WebDKP_Bench_SelectPlayerToggle()
--	local playerName = getglobal(this:GetName().."Name"):GetText();
--	if( WebDKP_BenchTable[playerName]["Selected"] ) then
--		WebDKP_BenchTable[playerName]["Selected"] = false;
--		getglobal(this:GetName() .. "Background"):SetVertexColor(0.2, 0.2, 0.7, 0.5);
--	else
--		WebDKP_BenchTable[playerName]["Selected"] = true;
--		getglobal(this:GetName() .. "Background"):SetVertexColor(0.1, 0.1, 0.9, 0.8);
--	end
--end

-- ================================
-- Selects all players in the dkp table and updates 
-- table display
-- ================================
function WebDKP_SelectAll()
	local tableid = WebDKP_GetTableid();
	for k, v in pairs(WebDKP_DkpTable) do
		if ( type(v) == "table" ) then
			local playerName = k; 
			local playerClass = v["class"];
			local playerDkp = v["dkp"..tableid];
			if ( playerDkp == nil ) then 
				v["dkp"..tableid] = 0;
				playerDkp = 0;
			end
			local playerTier = floor((playerDkp-1)/WebDKP_TierInterval);
			if (WebDKP_ShouldDisplay(playerName, playerClass, playerDkp, playerTier)) then
				WebDKP_DkpTable[playerName]["Selected"] = true;
			else
				WebDKP_DkpTable[playerName]["Selected"] = false;
			end
		end
	end
	WebDKP_UpdateTable();
end

-- ================================
-- Deselect all players and update table display
-- ================================
function WebDKP_UnselectAll()
	for k, v in pairs(WebDKP_DkpTable) do
		if ( type(v) == "table" ) then
			local playerName = k; 
			WebDKP_DkpTable[playerName]["Selected"] = false;
		end
	end
	WebDKP_UpdateTable();
end

-- ================================
-- Invoked when the gui loads up the drop down list of 
-- available dkp tables. 
-- ================================
function WebDKP_Tables_DropDown_OnLoad()
	UIDropDownMenu_Initialize(WebDKP_Tables_DropDown, WebDKP_Tables_DropDown_Init);
	
	local numTables = WebDKP_GetTableSize(WebDKP_Tables)
	if ( WebDKP_Tables == nil or numTables==0 or numTables==1) then
		WebDKP_Tables_DropDown:Hide();
	else
		WebDKP_Tables_DropDown:Show();
	end
end
-- ================================
-- Invoked when the drop down list of available tables
-- needs to be redrawn. Populates it with data 
-- from the tables data structure and sets up an 
-- event handler
-- ================================
function WebDKP_Tables_DropDown_Init()
	if( WebDKP_Frame.selectedTableid == nil ) then
		WebDKP_Frame.selectedTableid = 1;
	end
	local info;
	local selected = "";
	if ( WebDKP_Tables ~= nil and next(WebDKP_Tables)~=nil ) then
		for key, entry in pairs(WebDKP_Tables) do
			if ( type(entry) == "table" ) then
				info = { };
				info.text = key;
				info.value = entry["id"]; 
				info.func = WebDKP_Tables_DropDown_OnClick;
				if ( entry["id"] == WebDKP_Frame.selectedTableid ) then
					info.checked = ( entry["id"] == WebDKP_Frame.selectedTableid );
					selected = info.text;
				end
				UIDropDownMenu_AddButton(info);
			end
		end
	end
	UIDropDownMenu_SetSelectedName(WebDKP_Tables_DropDown, selected );
	UIDropDownMenu_SetWidth(200, WebDKP_Tables_DropDown);
end

-- ================================
-- Called when the user switches between
-- a different dkp table.
-- ================================
function WebDKP_Tables_DropDown_OnClick()
	WebDKP_Frame.selectedTableid = this.value;
	WebDKP_Options["SelectedTableId"] = this.value; 
	WebDKP_Tables_DropDown_Init();
	WebDKP_UpdateTableToShow(); --update who is in the table
	WebDKP_UpdateTable();       --update the gui
end


-- ================================
-- Toggles zero sum support
-- ================================
function WebDKP_ToggleZeroSum()
	-- is g, disable it
	if ( WebDKP_WebOptions["ZeroSumEnabled"] == 1 ) then
		WebDKP_WebOptions["ZeroSumEnabled"] = 0;
	-- is disabled, enable it
	else
		WebDKP_WebOptions["ZeroSumEnabled"] = 1;
	end
end


-- ================================
-- MiniMap Scrolling code. 
-- Credit goes to Outfitter and WoWWiki for the know how 
-- of how to pull this off. 
-- ================================

-- ================================
-- Called when the user presses the mouse button down on the
-- mini map button. Remembers that position in case they
-- attempt to start dragging
-- ================================
function WebDKP_MinimapButton_MouseDown()
	-- Remember where the cursor was in case the user drags
	
	local	vCursorX, vCursorY = GetCursorPosition();
	
	vCursorX = vCursorX / this:GetEffectiveScale();
	vCursorY = vCursorY / this:GetEffectiveScale();
	
	WebDKP_MinimapButton.CursorStartX = vCursorX;
	WebDKP_MinimapButton.CursorStartY = vCursorY;
	
	local	vCenterX, vCenterY = WebDKP_MinimapButton:GetCenter();
	local	vMinimapCenterX, vMinimapCenterY = Minimap:GetCenter();
	
	WebDKP_MinimapButton.CenterStartX = vCenterX - vMinimapCenterX;
	WebDKP_MinimapButton.CenterStartY = vCenterY - vMinimapCenterY;
end

function WebDKP_MinimapButton_Click()
	if IsShiftKeyDown() then
		PlaySound("igMiniMapOpen");
		WebDKP_AutoAwardToggle();
		GameTooltip:Hide()
		WebDKP_MinimapLoadTooltip()
		GameTooltip:Show()
	else
		PlaySound("igMainMenuOptionCheckBoxOn");
		ToggleDropDownMenu(nil, nil, this);
	end
end

-- ================================
-- Called when the user starts to drag. Shows a frame that is registered
-- to recieve on update signals, we can then have its event handler
-- check to see the current mouse position and update the mini map button
-- correctly
-- ================================
function WebDKP_MinimapButton_DragStart()
	WebDKP_MinimapButton.IsDragging = true;
	WebDKP_UpdateFrame:Show();
end

-- ================================
-- Users stops dragging. Ends the timer
-- ================================
function WebDKP_MinimapButton_DragEnd()
	WebDKP_MinimapButton.IsDragging = false;
	WebDKP_UpdateFrame:Hide();
end

-- ================================
-- Updates the position of the mini map button. Should be called
-- via the on update method of the update frame
-- ================================
function WebDKP_MinimapButton_UpdateDragPosition()
	-- Remember where the cursor was in case the user drags
	local	vCursorX, vCursorY = GetCursorPosition();
	
	vCursorX = vCursorX / this:GetEffectiveScale();
	vCursorY = vCursorY / this:GetEffectiveScale();
	
	local	vCursorDeltaX = vCursorX - WebDKP_MinimapButton.CursorStartX;
	local	vCursorDeltaY = vCursorY - WebDKP_MinimapButton.CursorStartY;
	
	--
	
	local	vCenterX = WebDKP_MinimapButton.CenterStartX + vCursorDeltaX;
	local	vCenterY = WebDKP_MinimapButton.CenterStartY + vCursorDeltaY;
	
	-- Calculate the angle
	
	local	vAngle = math.atan2(vCenterX, vCenterY);
	
	-- Set the new position
	
	WebDKP_MinimapButton_SetPositionAngle(vAngle);
	
	--Sandsten edit, and remember it ofc... stoopid
	WebDKP_Options["MiniMapButtonAngle"] = vAngle;
	
end

-- ================================
-- Helper method. Helps restrict a given angle from occuring within a restricted angle
-- range. Returns where the angle should be pushed to - before or after the resitricted
-- range. Used to block the minimap button from appear behind the default ui buttons
-- ================================
function WebDKP_RestrictAngle(pAngle, pRestrictStart, pRestrictEnd)
	if ( pAngle == nil ) then
		return pRestrictStart;
	end
	if ( pRestrictStart == nil or pRestrictStart == nil) then
		return pAngle;
	end

	if pAngle <= pRestrictStart
	or pAngle >= pRestrictEnd then
		return pAngle;
	end
	
	local	vDistance = (pAngle - pRestrictStart) / (pRestrictEnd - pRestrictStart);
	
	if vDistance > 0.5 then
		return pRestrictEnd;
	else
		return pRestrictStart;
	end
end

-- ================================
-- Sets the position of the mini map button based on the passed angle. 
-- Restricts the button from appear over any of the default ui buttons. 
-- ================================
function WebDKP_MinimapButton_SetPositionAngle(pAngle)
	local	vAngle = pAngle;
	
	-- Restrict the angle from going over the date/time icon or the zoom in/out icons
	
	local	vRestrictedStartAngle = nil;
	local	vRestrictedEndAngle = nil;
	
	if GameTimeFrame:IsVisible() then
		if MinimapZoomIn:IsVisible()
		or MinimapZoomOut:IsVisible() then
			vAngle = WebDKP_RestrictAngle(vAngle, 0.4302272732931596, 2.930420793963121);
		else
			vAngle = WebDKP_RestrictAngle(vAngle, 0.4302272732931596, 1.720531504573905);
		end
		
	elseif MinimapZoomIn:IsVisible()
	or MinimapZoomOut:IsVisible() then
		vAngle = WebDKP_RestrictAngle(vAngle, 1.720531504573905, 2.930420793963121);
	end
	
	-- Restrict it from the tracking icon area
	
	vAngle = WebDKP_RestrictAngle(vAngle, -1.290357134304173, -0.4918423429923585);
	
	--
	
	local	vRadius = 80;
	
	vCenterX = math.sin(vAngle) * vRadius;
	vCenterY = math.cos(vAngle) * vRadius;
	
	WebDKP_MinimapButton:SetPoint("CENTER", "Minimap", "CENTER", vCenterX - 1, vCenterY - 1);
	WebDKP_MinimapButton:SetFrameStrata("MEDIUM")
	
	--sandsten add a tooltip showing version
	WebDKP_MinimapButton:SetScript("OnEnter", function()
		WebDKP_MinimapLoadTooltip()
		GameTooltip:Show()
	end)
	
	WebDKP_MinimapButton:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	WebDKP_Options["MiniMapButtonAngle"] = vAngle;
	--gOutfitter_Settings.Options.MinimapButtonAngle = vAngle;
end

function WebDKP_MinimapLoadTooltip()
		GameTooltip:SetOwner(WebDKP_MinimapButton, "ANCHOR_LEFT");
		GameTooltip:SetText("WebDKP");
		GameTooltip:AddLine("Sandstens fork",1,1,1);
		GameTooltip:AddLine(SandstensForkVersion,1,1,1);
		if(WebDKP_Options["WebDKP_Enabled"]) then
			GameTooltip:AddLine("WebDKP Enabled - will award DKP for bosskills.",0,1,0);
			GameTooltip:AddLine("Shift click to toggle.",1,1,1);
		else
			GameTooltip:AddLine("WebDKP Disabled - will NOT award DKP for bosskills",1,0,0);
			GameTooltip:AddLine("Shift click to toggle.",1,1,1);
		end
end

-- ================================
-- Event handler for the update frame. Updates the minimap button
-- if it is currently being dragged. 
-- ================================
function WebDKP_OnUpdate(elapsed)
	if WebDKP_MinimapButton.IsDragging then
		WebDKP_MinimapButton_UpdateDragPosition();
	end
end


-- ================================
-- Initializes the minimap drop down
-- ================================
function WebDKP_MinimapDropDown_OnLoad()
	UIDropDownMenu_SetAnchor(10, -20, this, "TOPLEFT", this:GetName(), "TOPRIGHT");
	UIDropDownMenu_Initialize(this, WebDKP_MinimapDropDown_Initialize);
end

-- ================================
-- Adds buttons to the minimap drop down
-- ================================
function WebDKP_MinimapDropDown_Initialize()
	WebDKP_Add_MinimapDropDownItem("WebDKP Enabled - Award Automatically",WebDKP_AutoAwardToggle, WebDKP_Options["WebDKP_Enabled"]);
	WebDKP_Add_MinimapDropDownItem("DKP Table",WebDKP_ToggleGUI);
	WebDKP_Add_MinimapDropDownItem("Bidding",WebDKP_Bid_ToggleUI);
	WebDKP_Add_MinimapDropDownItem("Bench (beta-broken)",WebDKP_Bench_ToggleUI);
	WebDKP_Add_MinimapDropDownItem("Add decay flat",WebDKP_GiveoutDecayDialogBox_ToggleUI);
	WebDKP_Add_MinimapDropDownItem("Add decay percentage",WebDKP_GiveoutDecayPercentageDialogBox_ToggleUI);
	WebDKP_Add_MinimapDropDownItem("Fix Negative DKP",WebDKP_FixNegative_ToggleUI);
	WebDKP_Add_MinimapDropDownItem("Morale boost!",WebDKP_MoraleBoost);
	--WebDKP_Add_MinimapDropDownItem("Help",WebDKP_ToggleGUI);
end

function WebDKP_MoraleBoost()
	PlaySoundFile("Interface\\AddOns\\WebDKP\\morale.mp3")
end

function WebDKP_AutoAwardToggle()
	if(WebDKP_Options["WebDKP_Enabled"]) then
		WebDKP_Options["WebDKP_Enabled"] = false
		WebDKP_Print("WebDKP Disabled - will NOT award DKP for bosskills")
		WebDKP_MinimapButton:SetNormalTexture("Interface\\AddOns\\WebDKP\\\Textures\\MinimapButton_disabled")
	else
		WebDKP_Options["WebDKP_Enabled"] = true
		WebDKP_Print("WebDKP Enabled - will award DKP for bosskills.")
		WebDKP_MinimapButton:SetNormalTexture("Interface\\AddOns\\WebDKP\\\Textures\\MinimapButton")
	end
end

-- ================================
-- Helper method that adds individual entries into the minimap drop down
-- menu.
-- ================================
function WebDKP_Add_MinimapDropDownItem(text, eventHandler, checked)
	local info = { };
	if checked then info.checked = true end
	info.text = text;
	info.value = text; 
	info.owner = this;
	info.func = eventHandler; -- WebDKP_Tables_DropDown_OnClick;
	UIDropDownMenu_AddButton(info);
end


-- ================================
-- Helper method. Called whenever a player clicks on shift click
-- ================================
function WebDKP_ItemChatClick(itemString, itemLink)

	-- do a search for 'player'. If it can be found... this is a player link, not an item link. It can be ignored
	local idx = strfind(itemString, "player");
	
	if( idx == nil ) then
		-- check to see if the bidding frame wants to do anything with the information
		WebDKP_Bid_ItemChatClick(itemString, itemLink);
		
		-- put the item text into the award editbox as long as the table frame is visible
		if ( IsShiftKeyDown()) then
			local _,itemName,_ = WebDKP_GetItemInfo(itemString); 
			WebDKP_AwardItem_FrameItemName:SetText(itemName);
		end
	end
end
