-- ================================
-- BENCH FUNCTIONALITY
-- ================================



-- Data structure for sorting the table 
WebDKP_BenchSort = {
	["curr"] = 2,				-- the column to sort
	["way"] = 1					-- Desc
};

-- ================================
-- Toggles displaying the bench panel
-- ================================
function WebDKP_Bench_ToggleUI()
	--Updates the information about the online guildies
	GuildRoster();

	if ( WebDKP_BenchFrame:IsShown() ) then
		WebDKP_BenchFrame:Hide();
	else
		WebDKP_BenchFrame:Show();
	end
end

function WebDKP_FixNegative_ToggleUI()
	--Updates the information about the online guildies
	GuildRoster();
	--Fix negative dkp
	WebDKP_FixNegative();
end

function WebDKP_Bench_HandleMouseOver()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	local selected = WebDKP_Bench_IsSelected(playerName);
	
	if( not selected ) then
		getglobal(this:GetName() .. "Background"):SetVertexColor(0.2, 0.2, 0.7, 0.5);
	end
end

function WebDKP_Bench_HandleMouseLeave()
	local playerName = getglobal(this:GetName().."Name"):GetText();
	local selected = WebDKP_Bench_IsSelected(playerName);
	if( not selected ) then
		getglobal(this:GetName() .. "Background"):SetVertexColor(0, 0, 0, 0);
	end
end

function WebDKP_Bench_SelectPlayerToggle()
	local playerName = getglobal(this:GetName().."Name"):GetText();

	for key, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil ) then
				if ( v["Name"] == playerName) then 

					--local bgName = this:GetName().."Background";
					if (v["Selected"] == true) then
						v["Selected"] = false;
						getglobal(this:GetName() .. "Background"):SetVertexColor(0.2, 0.2, 0.7, 0.5);
						--getglobal(bgName):SetVertexColor(0, 0, 0, 0);
					else
						-- deselect all the others on the table
						WebDKP_Bench_DeselectAll();
						
						v["Selected"] = true;
						getglobal(this:GetName() .. "Background"):SetVertexColor(0.1, 0.1, 0.9, 0.8);
						--getglobal(bgName):SetVertexColor(0.1, 0.1, 0.9, 0.8);
					end
				end
			end
		end
	end

	WebDKP_Bench_UpdateTable();  
end



function WebDKP_Bench_IsSelected(playerName)
	--playerBid = playerBid + 0 ; 
	for key, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil ) then
				if ( v["Name"] == playerName ) then 
					return v["Selected"];
				end
			end
		end
	end
	return false;
end

function WebDKP_Bench_DeselectAll()
	for key, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil) then
				v["Selected"] = false;
			end
		end
	end
end

function WebDKP_Bench_SortBy(id)
	if ( WebDKP_BenchSort["curr"] == id ) then
		WebDKP_BenchSort["way"] = abs(WebDKP_BenchSort["way"]-1);
	else
		WebDKP_BenchSort["curr"] = id;
		if( id == 1) then
			WebDKP_BenchSort["way"] = 0;
		elseif ( id == 2 ) then
			WebDKP_BenchSort["way"] = 1; --columns with numbers need to be sorted different first in order to get DESC right
		elseif ( id == 3 ) then
			WebDKP_BenchSort["way"] = 1; --columns with numbers need to be sorted different first in order to get DESC right
		else
			WebDKP_BenchSort["way"] = 1; --columns with numbers need to be sorted different first in order to get DESC right
		end
		
	end
	-- update table so we can see sorting changes
	WebDKP_Bench_UpdateTable();
end



function WebDKP_Bench_UpdateTable()
	-- Copy data to the temporary array
	local entries = { };
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil and v["Earned"] ~= nil and v["Total"] ~=nil ) then			
				tinsert(entries,{v["Name"],v["Earned"],v["Total"],v["Date"]}); -- copies over name, bid, dkp, dkp-bid
			end
		end
	end
	
	-- SORT
	table.sort(
		entries,
		function(a1, a2)
			if ( a1 and a2 ) then
				if ( a1 == nil ) then
					return 1>0;
				elseif (a2 == nil) then
					return 1<0;
				end
				if ( WebDKP_BidSort["way"] == 1 ) then
					if ( a1[WebDKP_BidSort["curr"]] == a2[WebDKP_BidSort["curr"]] ) then
						return a1[1] > a2[1];
					else
						return a1[WebDKP_BidSort["curr"]] > a2[WebDKP_BidSort["curr"]];
					end
				else
					if ( a1[WebDKP_BidSort["curr"]] == a2[WebDKP_BidSort["curr"]] ) then
						return a1[1] < a2[1];
					else
						return a1[WebDKP_BidSort["curr"]] < a2[WebDKP_BidSort["curr"]];
					end
				end
			end
		end
	);
	
	local numEntries = getn(entries);
	local offset = FauxScrollFrame_GetOffset(WebDKP_BenchFrameScrollFrame);
	FauxScrollFrame_Update(WebDKP_BenchFrameScrollFrame, numEntries, 13, 13);
	
	-- Run through the table lines and put the appropriate information into each line
	for i=1, 13, 1 do
		local line = getglobal("WebDKP_BenchFrameLine" .. i);
		local nameText = getglobal("WebDKP_BenchFrameLine" .. i .. "Name");
		local earnedText = getglobal("WebDKP_BenchFrameLine" .. i .. "Earned");
		local totalText = getglobal("WebDKP_BenchFrameLine" .. i .. "Total");
		local index = i + FauxScrollFrame_GetOffset(WebDKP_BenchFrameScrollFrame); 
		
		if ( index <= numEntries) then
			local playerName = entries[index][1];
			local date = entries[index][4];
			line:Show();
			nameText:SetText(entries[index][1]);
			earnedText:SetText(entries[index][2]);
			totalText:SetText(entries[index][3]);

			-- kill the background of this line if it is not selected
			local playerNameOnly = string.split(playerName, " ");
			if( WebDKP_BenchList[playerNameOnly[1]] and (not WebDKP_BenchList[playerNameOnly[1]]["Selected"]) ) then
				getglobal("WebDKP_BenchFrameLine" .. i .. "Background"):SetVertexColor(0, 0, 0, 0);
			else
				getglobal("WebDKP_BenchFrameLine" .. i .. "Background"):SetVertexColor(0.1, 0.1, 0.9, 0.8);
			end
		else
			-- if the line isn't in use, hide it so we dont' have mouse overs
			line:Hide();
		end
	end
end

function WebDKP_Bench_ClearSelected()
	-- Update WebDKP_BenchList
	WebDKP_BenchList_temp = {};
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil and v["Earned"] ~= nil and v["Total"] ~=nil ) then		
				if( v["Selected"]) then
					WebDKP_BenchList_temp[key_name] = nil;
				else
					WebDKP_BenchList_temp[key_name] = WebDKP_BenchList[key_name];
				end
			end
		end
	end
	WebDKP_BenchList = WebDKP_BenchList_temp;

	WebDKP_Bench_UpdateTable();
end

function WebDKP_Bench_RemoveName(nameGiven, earned)
	-- Update WebDKP_BenchList
	-- Removes nameGiven from WebDKP_BenchList

	WebDKP_BenchList_temp = {};
	for key_name, v in pairs(WebDKP_BenchList) do
		if( key_name ~= nameGiven) then
			WebDKP_BenchList_temp[key_name] = WebDKP_BenchList[key_name];
		end
	end
	WebDKP_BenchList = WebDKP_BenchList_temp;

	WebDKP_Bench_UpdateTable();

	-- Announce locally about the bench change
	if(earned == nil) then
		DEFAULT_CHAT_FRAME:AddMessage(nameGiven.." was removed from bench.");
	else
		DEFAULT_CHAT_FRAME:AddMessage(nameGiven.." was awarded "..earned.." DKP and removed from bench.");
	end
end

function WebDKP_AlreadyOnBench(name)
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil ) then
				local temp = v["Name"];
				local tempName = string.split(v["Name"], " ");

				if(tempName[1] == name) then
					return true;
				end
			end
		end
	end
end

function WebDKP_Bench_GetDKP(name)
	--DEFAULT_CHAT_FRAME:AddMessage(name);
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			local nameList = string.split(v["Name"], " ");
			if( nameList[1] == name ) then
				local ret = v["Earned"];
				return tonumber(ret);
			end
		end
	end
end

function WebDKP_Bench_Add(name)
	-- Add players to bench list (check if they are not in raid?)
	if(WebDKP_AlreadyOnBench(name)) then 
		DEFAULT_CHAT_FRAME:AddMessage("Player is already on bench");
	elseif(WebDKP_IsInRaid(name)) then
		DEFAULT_CHAT_FRAME:AddMessage("Player "..name.." is in raid, and can't be put on bench.");
	else
		WebDKP_Bench_AddList(name); 
	end
	-- Clears the text after button pushed
	WebDKP_BenchFrameItem:SetText("");
end

function WebDKP_IsBenchChat(name, trigger)
	if ( string.find(string.lower(trigger), "!bench" )== 1 ) then
        return true
    end
    return false
end

function WebDKP_Bench_AddList(playerName)
		SetGuildRosterShowOffline(true);
		GuildRoster();
		local dkpEarned = 0;							-- how much dkp do they have now
		local dkpToday = WebDKP_Bench_TotalToday;		-- what they will have if they spend this
		local date  = date("%Y-%m-%d");					-- record what day player was put on bench
		local rank = WebDKP_GetGuildRank(playerName);
		local shownNameTag = playerName.." ("..rank..")";
		
		WebDKP_BenchList[playerName] = {			-- place their bid in the bid table (combine it with the date so 1 player can have multiple bids)
			["Name"] = shownNameTag,
			["Earned"] = dkpEarned,
			["Total"] = dkpToday,
			["Date"] = date,
		}
		
		if(WebDKP_BenchList[playerName]["Selected"]==nil) then
			WebDKP_BenchList[playerName]["Selected"] = false;
		end
		
		WebDKP_Bench_UpdateTable();
		
		SetGuildRosterShowOffline(false);

		-- Announce locally that player has been added
		DEFAULT_CHAT_FRAME:AddMessage(shownNameTag.." has been added to bench.");
end

function WebDKP_Bench_AwardSelected()
	-- find out who is selected
	local player, earned = WebDKP_Bench_GetSelected();
	local players = { player };
	local reason = "BenchDKP";

	-- if someone is selected, award them the item via the award class
	if ( player == nil ) then 
		WebDKP_Print("No player is chosen - Noone is awarded");
		PlaySound("igQuestFailed");
	else

		StaticPopupDialogs["BENCH_SINGLE_AWARD_PROMPT"] = {
			text = "Do you want to give player DKP for bench?",
		  	button1 = "Yes",
		  	button2 = "No",
		  	OnAccept = function()
				WebDKP_Bench_AddDKP(player, earned, reason)

				-- Clear selected
				WebDKP_Bench_ClearSelected();
		  	end,
		  	timeout = 0,
		  	--hasEditBox = true,
		  	whileDead = true,
		  	hideOnEscape = true,
		  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
		}
		StaticPopup_Show ("BENCH_SINGLE_AWARD_PROMPT")
	end
end

function WebDKP_Bench_AwardIfBench(playerToAward)
	local reason = "BenchDKP";
	local isBench, earned = WebDKP_Bench_IsBench(playerToAward);
	if(isBench) then
		WebDKP_Bench_AddDKP(playerToAward, earned, reason);

		-- Remove from bench after given bench DKP
		WebDKP_Bench_RemoveName(playerToAward, earned);
	end
end

function WebDKP_Bench_IsBench(playerToCheck)
	local ret = false;
	local earned;

	local playerList, earnedList = WebDKP_Bench_GetPlayersAndEarnedList();
	local numPlayers = table.getn(playerList);
	for i=1, numPlayers, 1 do
		local player = playerList[i];
		if(player == playerToCheck) then
			earned = earnedList[i];
			ret = true;
		end
	end
	return ret, earned;
end

function WebDKP_Bench_AwardAll()
	-- find out who is selected
	local total = WebDKP_Bench_TotalToday;
	local playerList, earnedList = WebDKP_Bench_GetPlayersAndEarnedList();

	StaticPopupDialogs["BENCH_FINAL_PROMPT"] = {
		text = "Do you want to give all benchers DKP and give Decay to all players?",
	  	button1 = "Yes",
	  	button2 = "No",
	  	OnAccept = function()
	  		local numPlayers = table.getn(playerList);
			for i=1, numPlayers, 1 do
				local player = playerList[i];
				local earned = earnedList[i];
				WebDKP_Bench_AddDKP(player, earned, "BenchDKP");
			end
			-- Do Decay before clearing bench aka total dkp today
			WebDKP_DecayToAll();
			-- Clear list 
			WebDKP_Bench_Clear();
			-- Set all players with negative DKP to 0 
			WebDKP_FixNegative();
	  	end,
	  	timeout = 0,
	  	--hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("BENCH_FINAL_PROMPT")
end

function WebDKP_Bench_AddDKPToGUI(toAward)
	-- Update today's total
	WebDKP_Bench_TotalToday = WebDKP_Bench_TotalToday + toAward;

	-- Update Earned +5 for all currently on bench
	WebDKP_Bench_UpdateList(toAward);
	DEFAULT_CHAT_FRAME:AddMessage("Total DKP today: "..WebDKP_Bench_TotalToday);
end

function WebDKP_Bench_Clear()
	-- Update today's total
	WebDKP_Bench_TotalToday = 0;

	-- Update WebDKP_BenchList
	WebDKP_BenchList = {};
	WebDKP_Bench_UpdateTable();
end

function WebDKP_Bench_AddButtonHandler()

	local nameToAdd = WebDKP_BenchFrameItem:GetText();
	local nameToAdd_Fixed = strupper(strsub(nameToAdd, 1, 1))..""..strlower(strsub(nameToAdd, 2));
	WebDKP_Bench_Add(nameToAdd_Fixed);
end

function WebDKP_Bench_ClearButtonHandler()
	StaticPopupDialogs["CLEAR_BENCH_PROMPT"] = {
		text = "Do you really want to clear the bench list?",
	  	button1 = "Yes",
	  	button2 = "No",
	  	OnAccept = function()
	      	WebDKP_Bench_Clear();
	  	end,
	  	timeout = 0,
	  	--hasEditBox = true,
	  	whileDead = true,
	  	hideOnEscape = true,
	  	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("CLEAR_BENCH_PROMPT")
end

function WebDKP_Bench_GetSelected()
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if(  v["Selected"] == true) then
				local nameString = tostring(v["Name"])
				local list = string.split(nameString, " ")
				return list[1], v["Earned"];
			end
		end
	end
	return nil, 0;
end

function WebDKP_Bench_GetPlayersAndEarnedList()
	local nameList = {};
	local earnedList = {};
	local i = 1;
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			local nameString = tostring(v["Name"])
			local list = string.split(nameString, " ")
			nameList[i] = list[1]
			earnedList[i] = v["Earned"]

		end
		i = i + 1;
	end
	if(WebDKP_BenchList) then
		return nameList, earnedList;
	end
	return nil, 0;
end



function WebDKP_Bench_UpdateList(toAward)
	local entries = { };
	for key_name, v in pairs(WebDKP_BenchList) do
		if ( type(v) == "table" ) then
			if( v["Name"] ~= nil and v["Earned"] ~= nil and v["Total"] ~=nil ) then		
				tinsert(entries,{v["Name"],v["Earned"],v["Total"],v["Date"]}); -- copies over name, bid, dkp, dkp-bid

			end
		end
	end
	
	local numEntries = getn(entries);
	local offset = FauxScrollFrame_GetOffset(WebDKP_BenchFrameScrollFrame);
	FauxScrollFrame_Update(WebDKP_BenchFrameScrollFrame, numEntries, 13, 13);
	
	-- Run through the table lines and put the appropriate information into each line
	for i=1, 13, 1 do
		local line = getglobal("WebDKP_BenchFrameLine" .. i);
		local nameText = getglobal("WebDKP_BenchFrameLine" .. i .. "Name");
		local earnedText = getglobal("WebDKP_BenchFrameLine" .. i .. "Earned");
		local totalText = getglobal("WebDKP_BenchFrameLine" .. i .. "Total");
		local index = i + FauxScrollFrame_GetOffset(WebDKP_BenchFrameScrollFrame); 
		
		if ( index <= numEntries) then
			local playerName = entries[index][1];
			local date = entries[index][4];


			local earnedTable = entries[index][2];
			local earnedInt = tonumber(earnedTable) + toAward;

			line:Show();
			nameText:SetText(entries[index][1]);
			earnedText:SetText(earnedInt);
			totalText:SetText(WebDKP_Bench_TotalToday);

			-- Update WebDKP_Bench_AddList
			local playerNameOnly = string.split(playerName, " ");
			WebDKP_BenchList[playerNameOnly[1]] = {			-- place their bid in the bid table (combine it with the date so 1 player can have multiple bids)
				["Name"] = playerName,
				["Earned"] = earnedInt,
				["Total"] = WebDKP_Bench_TotalToday,
				["Date"] = date,
			}


			-- kill the background of this line if it is not selected
			if( WebDKP_BenchList[playerNameOnly[1]] and (not WebDKP_BenchList[playerNameOnly[1]]["Selected"]) ) then
				getglobal("WebDKP_BenchFrameLine" .. i .. "Background"):SetVertexColor(0, 0, 0, 0);
			else
				getglobal("WebDKP_BenchFrameLine" .. i .. "Background"):SetVertexColor(0.1, 0.1, 0.9, 0.8);
			end
		else
			-- if the line isn't in use, hide it so we dont' have mouse overs
			line:Hide();
		end
	end
end

function WebDKP_Bench_Event()
	local name = arg2;
	local trigger = arg1;
	if(WebDKP_IsBenchChat(name,trigger)) then --Check that it has !bench
		local _, cmd = WebDKP_GetCmd(trigger); --Gets text after !bench

		
		local cmdList = string.split(cmd, " ");


		if(cmdList[1] == "add") then
			-- ADD
			--DEFAULT_CHAT_FRAME:AddMessage(cmdList[1]);
			if(cmdList[2]) then
				local nameGiven = cmdList[2];
				local nameToAdd_Fixed = strupper(strsub(nameGiven, 1, 1))..""..strlower(strsub(nameGiven, 2));

				if(WebDKP_AlreadyOnBench(nameToAdd_Fixed)) then --TODO, make the method after ive managed to add a player
					WebDKP_SendWhisper(name, nameToAdd_Fixed.." is already on bench.");
				else
					WebDKP_Bench_Add(nameToAdd_Fixed);
					WebDKP_SendWhisper(name, nameToAdd_Fixed.." has been added to bench.");
				end
			end


		elseif(cmdList[1] == "remove") then
			-- REMOVE
			if(cmdList[2]) then
				local nameGiven = cmdList[2];
				local nameToRemove_Fixed = strupper(strsub(nameGiven, 1, 1))..""..strlower(strsub(nameGiven, 2));

				if(WebDKP_AlreadyOnBench(nameToRemove_Fixed)) then --TODO, make the method after ive managed to add a player
					WebDKP_Bench_RemoveName(nameToRemove_Fixed, nil);
					WebDKP_SendWhisper(name, nameToRemove_Fixed.." has been removed from bench.");
				else
					WebDKP_SendWhisper(name, nameToRemove_Fixed.." is not on bench.");
				end
			end
		elseif(cmdList[1] == "list") then
			-- LIST ALL ON BENCH
			local size = 0;
			for key_name, v in pairs(WebDKP_BenchList) do
				size = size + 1;
			end

			WebDKP_SendWhisper(name,"On bench: "..size.." players");
			for key_name, v in pairs(WebDKP_BenchList) do
				local class = WebDKP_GetPlayerClass(key_name);
				WebDKP_SendWhisper(name, key_name.." ("..class..")");
			end
		else
			if(WebDKP_AlreadyOnBench(name)) then --TODO, make the method after ive managed to add a player
				if(cmd == "dkp") then
					-- return DKP 
					WebDKP_SendWhisper(name,"Earned ".. WebDKP_Bench_GetDKP(name) .. " DKP so far (out of: ".. WebDKP_Bench_TotalToday.." DKP.");
				else
					WebDKP_SendWhisper(name,"You are already on the bench list");
				end
					
			else
				if(WebDKP_IsInRaid(name)) then
					WebDKP_SendWhisper(name,"You are already in raid and can't be put on bench.");
				else
					WebDKP_SendWhisper(name,"You are now on the bench list. Stay ready near the raid if you want to receive dkp");
					WebDKP_Bench_AddList(name); --TODO (move it above the whisper method above)
				end
			end
		end
	end
end


