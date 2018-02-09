--[[
Airdash manager
]]

--TODO: JUICE THIS BADBOY UP

COOLDOWNTIME = 0
DASHDISTANCE = 10 -- In blocks

local players = {}

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	players[playerName] = {
		lastBoost = 0 
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

minetest.register_globalstep(function(dtime)

	local gameTime = minetest.get_gametime()

	-- Check all online players.
	for playerName,playerInfo in pairs(players) do
		local player = minetest.get_player_by_name(playerName)
		if player ~= nil then
			if player:get_player_control()["aux1"] and players[playerName]["lastBoost"] < (gameTime - COOLDOWNTIME) then
				doBoost(playerName)
			end
			
			
		end
	end
end)

--[[
Takes the player name who's dashing.
Checks line of sight for any obstructions and changes the destination accordingly.
Fires off a interpolated move_to as a result.
]]
function doBoost(playerName)
	local gameTime = minetest.get_gametime()
	local player = minetest.get_player_by_name(playerName)
	if players[playerName] then
		players[playerName]["lastBoost"] = gameTime
		local playerPos = player:get_pos()
		local playerCamDir = vector.normalize(player:get_look_dir())
		
		local dash = vector.multiply(playerCamDir, DASHDISTANCE)
		
		-- Check if we hit anything on the way
		local testPos = playerPos
		testPos.y = testPos.y + 1.5
		local landPoint = vector.add(dash, playerPos)
		local lineSight, lineLand = minetest.line_of_sight(playerPos, landPoint, 0.01)
		if lineSight == false then
			local vectorDiff = vector.subtract(playerPos, lineLand)
			vectorDiff = vector.length(vectorDiff) - 1
			minetest.chat_send_all(tostring(vectorDiff))
			if vectorDiff <= 0 then
				return false
			end
			dash = vector.multiply(playerCamDir, vectorDiff)
		end
		
		-- Sometimes the game spawns us below where we gotta be, this tries to check for that
		local yTest = dash
		yTest.y = yTest.y - 1.1
		
		if minetest.get_node(yTest) ~= "default:air" then
			dash.y = dash.y + 1.1
		end
		
		dash = vector.add(dash, playerPos)
		dash.x = round(dash.x)
		dash.z = round(dash.z)
		player:set_physics_override({gravity=0.3}) -- To lessen stutter mid dash
		smoothMove(playerName, dash, 30, 0.4)
		return true
	end
	return false
end

-- Interpolate move_to()
-- Input is player to move, position to move to, keyframes, and time delay
function smoothMove(playerName, pos, steps, delay)
	local player = minetest.get_player_by_name(playerName)
	
	if players[playerName] then
		local playerPos = player:get_pos()
		local interval = delay / steps
		local jumpLength = vector.divide(vector.subtract(pos, playerPos), steps)
		local jump = 0
		local iInterval = 0
			for i = 1, steps do
				jump = vector.add(playerPos,(vector.multiply(jumpLength,i)))
				iInterval = interval * i
				minetest.after(iInterval, doMove, playerName, jump, pos)
			end
	end
end

function doMove(playerName, jump, endPos)
	local player = minetest.get_player_by_name(playerName)
	
	if players[playerName] then
		if vector.equals(jump, endPos) then
			player:set_physics_override({gravity=1}) -- To reset the physics set before SmoothMove()
		end
		player:move_to(jump, false)
	end

end

function round(input)
	local output = input + 0.5 - (input + 0.5) % 1
	return output
end