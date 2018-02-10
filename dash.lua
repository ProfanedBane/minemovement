--[[
Airdash manager
]]
--TODO: Fix slight vertical phasing
--TODO: Fix phasing into blocks by placing one as you dash
--TODO: Fix moving into positions where a block is in the top half of the player body: DONE(?)
--TODO: JUICE THIS BADBOY UP

COOLDOWNTIME = 1 -- In gametime (seconds)
DASHDISTANCE = 10 -- In blocks
HEIGHTMODIFIER = 1.5 -- Add to the line of sight check's y level

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
		playerPos.y = playerPos.y + HEIGHTMODIFIER -- for some reason this makes everything work better
		local playerCamDir = vector.normalize(player:get_look_dir())
		
		local dash = vector.multiply(playerCamDir, DASHDISTANCE)
		
		-- Check if we hit anything on the way
		dash = verifyMove(playerPos, dash, playerCamDir)
		if dash == false then
			return false
		end
		dash = vector.add(dash, playerPos)
		-- round to prevent phasing into blocks
		dash.y = (round(dash.y) - 0.5)
		dash.x = round(dash.x)
		dash.z = round(dash.z)
		
		minetest.chat_send_all(minetest.pos_to_string(dash))
		smoothMove(playerName, dash, 15, 0.4)
		return true
	end
	return false
end

function verifyMove(startPos, moveVector, moveDir)

	while vector.length(moveVector) > 0 do
		
		-- check where our feet are
		local endPos = vector.add(moveVector, startPos)
		-- if aiming up check the block below
		if moveDir.y > 0 then
			endPos.y = endPos.y - 1
		end
		
		local lineSightA, lineLandA = minetest.line_of_sight(startPos, endPos, 0.01) -- high precision to prevent movement through diagonal barriers
		if lineSightA == false then
			local vectorDiff = vector.subtract(startPos, lineLandA)
			vectorDiff = vector.length(vectorDiff) - 1
			if round(vectorDiff) <= 0 then
				break
			end
			moveVector = vector.multiply(moveDir, vectorDiff)
		end
			
		-- Now check eye-level
		endPos = vector.add(moveVector, startPos)
		if moveDir.y <= 0 then
			endPos.y = endPos.y + 1
		end
		
		local lineSightB, lineLandB = minetest.line_of_sight(startPos, endPos, 0.01) -- high precision to prevent movement through diagonal barriers
		if lineSightB == false then
			local vectorDiff = vector.subtract(startPos, lineLandB)
			vectorDiff = vector.length(vectorDiff) - 1
			if round(vectorDiff) <= 0 then
				break
			end
			moveVector = vector.multiply(moveDir, vectorDiff)
		end
		
		if lineSightA == true and lineSightB == true then
			return moveVector
		end
		
	end
	return false
end

-- Interpolate move_to()
-- Input is player to move, position to move to, keyframes, and time delay
function smoothMove(playerName, pos, steps, delay)
	local player = minetest.get_player_by_name(playerName)
	
	if players[playerName] then
		players[playerName]["move_keyframe"] = 0
		local playerPos = player:get_pos()
		local interval = delay / steps
		local jumpLength = vector.divide(vector.subtract(pos, playerPos), steps)
		local jump = 0
		local iInterval = 0
		minetest.sound_play("whoosh", {
			to_player = player,
			gain = 0.3,
		})
		
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