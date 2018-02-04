--[[
doublejump manager
]]

local players = {}

JUMPTIME = 0.2
EYEHEIGHT = 0.2

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	players[playerName] = {
		doubleJumpTrigger = false,
		doubleJumped = false,
		jumpRelease = false
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
			
			if player:get_player_control()["jump"] and players[playerName]["jumpRelease"] == true and players[playerName]["doubleJumped"] == false then
				players[playerName]["doubleJumped"] = true
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
		player:set_physics_override({gravity=-3}) -- To lessen stutter mid dash
		minetest.after(JUMPTIME, endJump, playerName)
		return true
	end
	return false
end

function endJump(playerName)
	local player = minetest.get_player_by_name(playerName)
	if players[playerName] then
		player:set_physics_override({gravity=1})
	end
end

	