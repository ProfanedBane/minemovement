--[[
Airdash manager
]]
--TODO: Fix slight vertical phasing
--TODO: Fix moving into positions where a block is in the top half of the player body
--TODO: JUICE THIS BADBOY UP

COOLDOWNTIME = 0 -- In gameticks
DASHDISTANCE = 10 -- In blocks

local players = {}

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	players[playerName] = {
		lastBoost = 0, 
		move_keyframe = 0
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
		playerPos.y = playerPos.y + 1.5 -- for some reason this makes everything work better
		local playerCamDir = vector.normalize(player:get_look_dir())
		
		local dash = vector.multiply(playerCamDir, DASHDISTANCE)
		
		-- Check if we hit anything on the way
		local testPos = vector.new(playerPos) -- use vector.new() else it's a reference and that mucks everything up
		local landPoint = vector.add(dash, playerPos)
		local lineSight, lineLand = minetest.line_of_sight(playerPos, landPoint, 0.01) -- high precision to prevent movement through diagonal barriers
		if lineSight == false then
			local vectorDiff = vector.subtract(playerPos, lineLand)
			vectorDiff = vector.length(vectorDiff) - 1
			minetest.chat_send_all(tostring(vectorDiff))
			if vectorDiff <= 0 then
				return false
			end
			dash = vector.multiply(playerCamDir, vectorDiff)
		end
		
		local finalDash = vector.add(dash, playerPos)
		-- round to prevent phasing into blocks
		finalDash.y = (round(finalDash.y) - 0.5)
		finalDash.x = round(finalDash.x)
		finalDash.z = round(finalDash.z)
		minetest.chat_send_all(minetest.pos_to_string(finalDash))
		players[playerName]["move_keyframe"] = 0
		smoothMove(playerName, finalDash, 15, 0.4)
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
				minetest.after(iInterval, doMove, playerName, jump, pos, i)
			end
	end
end

function doMove(playerName, jump, endPos, keyframe)
	local player = minetest.get_player_by_name(playerName)
	
	if players[playerName] then
		-- In Minetest, the flow of time is distorted. The flow of time itself is convoluted; with keyframes centuries old phasing in and out. 
		if players[playerName]["move_keyframe"] > keyframe then
			return false -- disregard misordered frames
		end
		player:move_to(jump, true)
		players[playerName]["move_keyframe"] = keyframe
		if vector.equals(jump, endPos) then
			--do anything we need to do at the end of the move
			players[playerName]["move_keyframe"] = keyframe + 1
		end
	end

end

function round(input)
	local output = input + 0.5 - (input + 0.5) % 1
	return output
end