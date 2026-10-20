-- /rtp: teleport to a random safe spot in a box around a centre.

local searching = {} -- searching[name] = true while a search is running

local function setting_int(key, default)
	return tonumber(core.settings:get("teleportation." .. key)) or default
end

-- "x, y, z" with or without the parentheses the settings menu writes
local function origin()
	local text = (core.settings:get("teleportation.rtp_origin") or ""):gsub("[()]", "")
	return vector.from_string("(" .. text .. ")") or vector.zero()
end

local function safe_feet(pos)
	local def = core.registered_nodes[core.get_node(pos).name]
	return def ~= nil and not def.walkable and (def.liquidtype or "none") == "none"
		and (def.damage_per_second or 0) <= 0
end

local function safe_floor(pos)
	local def = core.registered_nodes[core.get_node(pos).name]
	return def ~= nil and def.walkable and (def.damage_per_second or 0) <= 0
end

-- every spot in the column that can be stood on
local function spots(x, z, ymin, ymax)
	local list = {}
	for y = ymin, ymax do
		local feet = vector.new(x, y, z)
		if core.get_node_or_nil(feet) and safe_feet(feet)
			and safe_feet(vector.new(x, y + 1, z))
			and safe_floor(vector.new(x, y - 1, z)) then
			list[#list + 1] = feet
		end
	end
	return list
end

-- Which column to look at: { x, z, ymin, ymax, highest = true to take the top
-- spot instead of a random one }. A game specific search can replace this
-- (see skyblock_zero.lua); it may also return nil, reason to give up.
function teleportation.pick_column(o, rx, ry, rz)
	return {
		x = math.floor(o.x + math.random(-rx, rx)),
		z = math.floor(o.z + math.random(-rz, rz)),
		ymin = math.max(math.floor(o.y - ry), -30000),
		ymax = math.min(math.floor(o.y + ry), 30000),
	}
end

local function search(name, attempts_left, o, rx, ry, rz)
	local player = core.get_player_by_name(name)
	if not player then searching[name] = nil return end
	if attempts_left <= 0 then
		searching[name] = nil
		core.chat_send_player(name, "Couldn't find a safe spot to teleport to. Try again.")
		return
	end
	local col, why = teleportation.pick_column(o, rx, ry, rz)
	if not col then
		searching[name] = nil
		core.chat_send_player(name, why or "Couldn't find a place to teleport to.")
		return
	end
	local x, z, ymin, ymax = col.x, col.z, col.ymin, col.ymax
	core.emerge_area(vector.new(x, ymin, z), vector.new(x, ymax, z), function(_, _, remaining)
		if remaining > 0 then return end
		local found = spots(x, z, ymin, ymax)
		local p = core.get_player_by_name(name)
		if not p then searching[name] = nil return end
		if #found == 0 then
			return search(name, attempts_left - 1, o, rx, ry, rz)
		end
		local spot = col.highest and found[#found] or found[math.random(#found)]
		searching[name] = nil
		p:set_pos(vector.new(spot.x, spot.y, spot.z))
		core.log("action", ("[teleportation] /rtp %s -> %d, %d, %d"):format(name, spot.x, spot.y, spot.z))
		core.chat_send_player(name, ("Teleported to %d, %d, %d."):format(spot.x, spot.y, spot.z))
	end)
end

core.register_chatcommand("rtp", {
	description = "Teleport to a random place",
	func = function(name)
		if not core.get_player_by_name(name) then return false, "You must be online." end
		if searching[name] then return false, "Already looking for a spot." end
		searching[name] = true
		search(name, setting_int("rtp_attempts", 10), origin(),
			setting_int("rtp_range_x", 1000), setting_int("rtp_range_y", 150), setting_int("rtp_range_z", 1000))
		return true, "Looking for a spot..."
	end,
})

core.register_on_leaveplayer(function(player)
	searching[player:get_player_name()] = nil
end)
