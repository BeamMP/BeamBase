--=================================================================
-- BeamBase
-- By Titch
--=================================================================
-- Configuration
--=================================================================
--    Settings        = Value (true/false)
--=================================================================
local admins = {
	"beammp:62932", -- Unsure
	"beammp:342659", -- Titch
	"beammp:124353" -- Leo
}

local allowGuests = true
local allowGuestChat = false
--=================================================================
-- DO NOT TOUCH BEYOND THIS POINT
--=================================================================

pluginPath = debug.getinfo(1).source:gsub("\\","/")
pluginPath = pluginPath:sub(2,(pluginPath:find("main.lua"))-2)

package.path = package.path .. ";;" .. pluginPath .. "/?.lua;;".. pluginPath .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.dll;;" .. pluginPath .. "/lib/?.dll"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.so;;" .. pluginPath .. "/lib/?.so"

function trim(s)
  -- from PiL2 20.4
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function checkAdmin(identifiers)
	for TYPE, ID in pairs(identifiers) do
		for _, admin in pairs(admins) do
			--print(admin .. ' -> '..TYPE .. ":" ..ID)
			if TYPE..":"..ID == admin then
				--print('Harry, your a ~wizard~ admin!!')
				return true
			end
		end
	end
	return false
end

function split(str, patt)
	vals = {}; valindex = 0; word = ""
	-- need to add a trailing separator to catch the last value.
	str = str .. patt
	for i = 1, string.len(str) do
	
		cha = string.sub(str, i, i)
		if cha ~= patt then
			word = word .. cha
		else
			if word ~= nil then
				vals[valindex] = word
				valindex = valindex + 1
				word = ""
			else
				-- in case we get a line with no data.
				break
			end
		end 
	end	
	return vals
end

-- Load the bans list
local bans = {}

function onInit()
	print('BeamBase Starting!')
	local bans_file = io.open(pluginPath.."/bans.txt")
	print('Loading Banned Players List..')
	if not bans_file then 
		print('FAILED TO LOAD BANS FILE!!!')
		return
	end
	local count = 0
	for line in bans_file:lines() do
		count = count + 1
		print('    '..line)
		table.insert(bans, line);
	end
	print(count..' Bans Loaded.')
end

function toboolean(str)
    local bool = false
    if str == "true" or str == "1" then
        bool = true
    end
    return bool
end

print('LOADED!!!!')

function onChatMessage(id, name, message)
	local isGuest = true
	local identifiers = MP.GetPlayerIdentifiers(id)
	
	if not allowGuestChat then
		for TYPE, ID in pairs(identifiers) do
			print(TYPE)
			if TYPE == 'beammp' then
				isGuest = false
			end
		end
		
		if isGuest and not allowGuestChat then
			MP.SendChatMessage(id, '^4Sorry Chat for Guest Accounts is Disabled on this server.')
			return 1
		end
	end
	
	local message = trim(message)
	message = split(message, ' ')
	
	if message[0] == '/help' then
		if checkAdmin(identifiers) then
			MP.SendChatMessage(id, 'The following Commands are available:')
			MP.SendChatMessage(id, '/help - This help message')
			MP.SendChatMessage(id, '/players - Display a list of players and their ID')
			MP.SendChatMessage(id, '/say - Say a message as the server.')
			MP.SendChatMessage(id, '/id /identifiers <optional id> - Show yours/another players identifiers')
			MP.SendChatMessage(id, '/allowGuestChat <true|false|1|0> - Allow Guests to use the chat')
			MP.SendChatMessage(id, '/allowGuests <true|false|1|0>- Allow Guests to join the server.... or not')
			MP.SendChatMessage(id, '/kick <id> <reason> - Kick a player')
			MP.SendChatMessage(id, '/ban <id> <reason> - Ban a player')
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end
	
	if message[0] == '/say' then
		if checkAdmin(identifiers) then
			if message[1] then
				message[0] = ''
				msg = table.concat(message, ' ')
				MP.SendChatMessage(-1, tostring(msg))
			else
				MP.SendChatMessage(id, 'Please provide a message to send to the server.')
			end
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end
	
	if message[0] == '/allowGuests' then
		if checkAdmin(identifiers) then
			if message[1] then
				allowGuests = toboolean(message[1])
				MP.SendChatMessage(id, 'Allow Guests has now been set to: '..message[1])
			else 
				MP.SendChatMessage(id, 'Allow Guests is currently set to: '..tostring(allowGuests))
			end
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end
	
	if message[0] == '/allowGuestChat' then
		if checkAdmin(identifiers) then
			if message[1] then
				allowGuestChat = toboolean(message[1])
				MP.SendChatMessage(id, 'Allow Guest Chat has now been set to: '..message[1])
			else 
				MP.SendChatMessage(id, 'Allow Guest Chat is currently set to: '..tostring(allowGuestChat))
			end
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end
	
	if message[0] == '/players' then
		if checkAdmin(identifiers) then
			MP.SendChatMessage(id, 'There are currently '..MP.GetPlayerCount()..' on the server')
			local players = MP.GetPlayers()
			for playerID, playerName in pairs(players) do
				MP.SendChatMessage(id, 'ID: '..playerID..' Name: '..playerName)
			end
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end

	if message[0] == '/id' or message[0] == '/identifiers' then
		if message[1] then
			MP.SendChatMessage(id, 'Player '..message[1].."'s identifiers:")
			for TYPE, ID in pairs(MP.GetPlayerIdentifiers(tonumber(message[1]))) do
				MP.SendChatMessage(id, 'ID: '..TYPE..' Name: '..ID)
			end
		else
			MP.SendChatMessage(id, 'Your identifiers:')
			for TYPE, ID in pairs(identifiers) do
				MP.SendChatMessage(id, 'Type: '..TYPE..' Value: '..ID..' (Raw: '..TYPE..':'..ID..')')
			end
		end
		return 1
	end
	
	if message[0] == '/kick' then
		if checkAdmin(identifiers) then
			local players = MP.GetPlayers()
			for playerID, playerName in pairs(players) do
				print(playerID, message[1])
				if message[1] == tostring(playerID) then
					
					if message[2] then
						message[0] = ''
						message[1] = ''
						msg = table.concat(message, ' ')
						MP.DropPlayer(tonumber(playerID), msg)
						MP.SendChatMessage(-1, playerName..' was kicked from the server.')
						MP.SendChatMessage(-1, 'Reason: '..msg)
					else
						MP.DropPlayer(tonumber(playerID))
						MP.SendChatMessage(-1, playerName..' was kicked from the server.')
					end
				end
			end
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end

	if message[0] == '/ban' then
		if checkAdmin(identifiers) then
			local players = MP.GetPlayers()
			for playerID, playerName in pairs(players) do
				if message[1] == ''..playerID then
					local ids = MP.GetPlayerIdentifiers(playerID)
					if checkAdmin(ids) then
						-- Do not allow admins to ban admins
						MP.SendChatMessage(id, '^4You cannot ban another server admin.')
					else 
						MP.DropPlayer(tonumber(message[1]))
						local file = io.open("bans.txt", "a");
						for TYPE, ID in pairs(ids) do
							file:write(ID, "\n")
							table.insert (bans, ID);
						end
						MP.SendChatMessage(-1, playerName..' was banned.')
						if message[2] then
							message[0] = ''
							message[1] = ''
							msg = table.concat(message, ' ')
							MP.SendChatMessage(-1, 'Reason: '..msg)
						end
					end
				end
			end
		else 
			MP.SendChatMessage(id, '^4Insufficient Permissions')
		end
		return 1
	end
end

function onPlayerAuth(name, role, isGuest)
	if isGuest and not allowGuests then
		return "You must be signed in to join this server!"
	end
	
	--local ids = MP.GetPlayerIdentifiers(playerID)
	
	if not isGuest and role == "STAFF" then

		--table.insert(admins, 
	end
	if not isGuest and role == "MDEV" then
		
	end
end

function onPlayerConnecting(id)
	print('Player '..MP.GetPlayerName(id)..' ('..id..') connecting.')
	local identifiers = MP.GetPlayerIdentifiers(id)
	for TYPE, ID in pairs(identifiers) do
		--print(TYPE, ID)
		for _, player in pairs(bans) do
			if ID == player then
				print('Connecting Player "'..MP.GetPlayerName(id)..'" is banned from the server.')
				MP.DropPlayer(id, 'You are banned from the server.')
				return 1
			end
		end
	end
end

MP.RegisterEvent("onPlayerAuth","onPlayerAuth")
MP.RegisterEvent("onPlayerConnecting","onPlayerConnecting")
MP.RegisterEvent("onChatMessage","onChatMessage")