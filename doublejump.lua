--[[
doublejump manager
]]

local players = {}

JUMPTIME = 0.1
EYEHEIGHT = 0.2
GRAVITYACCEL = 20
JUMPVEL = 20

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	players[playerName] = {
		doubleJumpTrigger = false,
		doubleJumped = false,
		jumpRelease = false,
		isDoubleJumping = false
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

minetest.register_globalstep(function(dtime)

	-- Check all online players.
	for playerName,playerInfo in pairs(players) do
		local player = minetest.get_player_by_name(playerName)
		if player ~= nil then
			local playerVelocity = player:get_player_velocity()
			local yVelocity = playerVelocity.y

			--minetest.chat_send_all(tostring(yVelocity))
			
			local playerPos = player:get_pos()
			local checkPos = player:get_pos()
			checkPos.y = checkPos.y - EYEHEIGHT
			
			local inAir = minetest.line_of_sight(playerPos, checkPos)
			
			if player:get_player_control()["jump"] == false and players[playerName]["doubleJumpTrigger"] == true then
				players[playerName]["jumpRelease"] = true
			end
			
			if inAir == false and yVelocity == 0 and (players[playerName]["doubleJumped"] == true or players[playerName]["doubleJumpTrigger"] == true) then
				players[playerName]["doubleJumped"] = false
				players[playerName]["doubleJumpTrigger"] = false
				players[playerName]["jumpRelease"] = false
			end
			
			if player:get_player_control()["jump"] and players[playerName]["jumpRelease"] == true and players[playerName]["doubleJumped"] == false and players[playerName]["isDoubleJumping"] == false then
				players[playerName]["doubleJumped"] = true
				players[playerName]["isDoubleJumping"] = true
				doubleJump(playerName)
			end
			
			if (player:get_player_control()["jump"] or yVelocity ~= 0) and players[playerName]["doubleJumped"] == false then
				players[playerName]["doubleJumpTrigger"] = true
			end
			
			
		end
	end
end)

function doubleJump(playerName)
	local player = minetest.get_player_by_name(playerName)
	if players[playerName] then
		local playerVelocity = player:get_player_velocity()
		local yVelocity = playerVelocity.y
		
		local gravActual = GRAVITYACCEL * JUMPTIME
		local gravToZero = yVelocity / gravActual
		
		if math.floor(yVelocity + 0.5) == 0 then
			gravToZero = 0
		end
		
		minetest.chat_send_all(tostring(yVelocity))
		minetest.chat_send_all(tostring(gravToZero))
		
		local jumpMod = -JUMPVEL/gravActual
		local finalGrav = jumpMod + gravToZero
		
		--minetest.chat_send_all(tostring(jumpMod))
		minetest.chat_send_all(tostring(finalGrav))
		
		player:set_physics_override({gravity=finalGrav}) -- To lessen stutter mid dash
		minetest.after(JUMPTIME, endJump, playerName)
		return true
	end
	return false
end

function endJump(playerName)
	local player = minetest.get_player_by_name(playerName)
	if players[playerName] then
		players[playerName]["isDoubleJumping"] = false
		local playerVelocity = player:get_player_velocity()
		local yVelocity = playerVelocity.y
		--minetest.chat_send_all(tostring(yVelocity))
		player:set_physics_override({gravity=1})
	end
end

	