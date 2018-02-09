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
		--local camPos = vector.new(playerPos)
		--camPos.y = camPos.y + 1.5 --moves position to the camera
		minetest.chat_send_all(minetest.pos_to_string(playerPos))
		local playerCamDir = vector.normalize(player:get_look_dir())
		
		local dash = vector.multiply(playerCamDir, DASHDISTANCE)
		
		-- Check if we hit anything on the way
		minetest.chat_send_all(minetest.pos_to_string(dash))
		local landPoint = vector.add(dash, playerPos)
		local lineSight, lineLand = minetest.line_of_sight(playerPos, landPoint, 0.01) --high precision to prevent movement through diagonal barriers
		
		--minetest.spawn_item(playerPos, "leaves")
		--minetest.spawn_item(landPoint, "leaves")
		--minetest.spawn_item(lineLand, "leaves")
		
		if lineSight == false then
			local vectorDiff = vector.subtract(playerPos, lineLand)
			local vectorDiffLength = vector.length(vectorDiff) - 1
			minetest.chat_send_all(minetest.pos_to_string(lineLand))
			minetest.chat_send_all(tostring(vectorDiffLength))
			if vectorDiffLength <= 0 then
				return false
			end
			dash = vector.multiply(playerCamDir, vectorDiffLength)
		end
		
		--increased LoS precision fixes this???

		-- Sometimes the game spawns us below where we gotta be, this tries to check for that
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		local yTest = vector.new(dash) -- Have to use 'vector.new()' while duplicating vectors, else I believe it's a reference
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		yTest.y = yTest.y - 1.5
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		yTest = vector.add(yTest, playerPos)
		minetest.spawn_item(yTest, "wood")
		local yTestNode = minetest.get_node(yTest)
		local yTestWalkable = minetest.registered_nodes[yTestNode.name].walkable
		
		if yTestWalkable == true then
			minetest.chat_send_all("meme0")
			dash.y = dash.y + 1
		end
		
		
		-- Actually let's also look for blocks where our head is, or blocks in general.
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		yTest = vector.new(dash) -- Have to use 'vector.new()' while duplicating vectors, else I believe it's a reference
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		
		--yTest.y = yTest.y + 1.0
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		yTest = vector.add(yTest, playerPos)
		minetest.spawn_item(yTest, "leaves")
		yTestNode = minetest.get_node(yTest)
		yTestWalkable = minetest.registered_nodes[yTestNode.name].walkable
		--minetest.chat_send_all(tostring(yTestWalkable))
		if yTestNode.walkable  == true then
			minetest.chat_send_all("memes")
			return false --invalid move
		end
		
		--minetest.chat_send_all(minetest.pos_to_string(dash))
		dash = vector.add(dash, playerPos)
		dash.x = round(dash.x)
		dash.z = round(dash.z)
		--player:set_physics_override({gravity=0.3}) -- To lessen stutter mid dash
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
		minetest.sound_play("whoosh", {
			to_player = player,
			gain = 0.3,
		})
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
			--player:set_physics_override({gravity=1}) -- To reset the physics set before SmoothMove()
		end
		player:move_to(jump, false)
	end

end

function round(input)
	local output = input + 0.5 - (input + 0.5) % 1
	return output
end