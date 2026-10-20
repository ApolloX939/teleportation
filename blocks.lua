-- Who doesn't want requests. Kept in mod storage:
-- blocks[target] = { all = true, names = { [requester] = true } }

local storage = core.get_mod_storage()
local saved = storage:get_string("blocks")
local blocks = saved ~= "" and core.parse_json(saved) or {}

local function save()
	storage:set_string("blocks", core.write_json(blocks))
end

local function entry(name)
	local e = blocks[name]
	if not e then
		e = { names = {} }
		blocks[name] = e
	end
	e.names = e.names or {}
	return e
end

function teleportation.is_blocked(target, requester)
	local e = blocks[target]
	if not e then return false end
	return e.all == true or (e.names or {})[requester] == true
end

function teleportation.block_all(name, on)
	local e = entry(name)
	e.all = on or nil
	save()
end

function teleportation.blocks_all(name)
	return (blocks[name] or {}).all == true
end

function teleportation.block(name, other)
	entry(name).names[other] = true
	save()
end

function teleportation.unblock(name, other)
	local e = blocks[name]
	if not e or not e.names[other] then return false end
	e.names[other] = nil
	save()
	return true
end

function teleportation.blocked_names(name)
	local list = {}
	for other in pairs((blocks[name] or {}).names or {}) do list[#list + 1] = other end
	table.sort(list)
	return list
end

core.register_chatcommand("tpblock", {
	params = "<player>",
	description = "Automatically deny teleport requests from a player",
	func = function(name, param)
		local other = param:trim()
		if other == "" then return false, "Usage: /tpblock <player>" end
		if other == name then return false, "You can't block yourself." end
		if not core.player_exists(other) then return false, "No such player: " .. other end
		teleportation.block(name, other)
		teleportation.drop_requests(name, other)
		return true, "Requests from " .. other .. " are blocked. /tpunblock " .. other .. " to allow them again."
	end,
})

core.register_chatcommand("tpunblock", {
	params = "<player>",
	description = "Stop blocking teleport requests from a player",
	func = function(name, param)
		local other = param:trim()
		if other == "" then return false, "Usage: /tpunblock <player>" end
		if teleportation.unblock(name, other) then
			return true, "Requests from " .. other .. " are allowed again."
		end
		return false, other .. " isn't blocked."
	end,
})

core.register_chatcommand("tpblockall", {
	params = "[on|off]",
	description = "Block (or allow again) all teleport requests; no argument toggles",
	func = function(name, param)
		param = param:trim():lower()
		local on
		if param == "on" then on = true
		elseif param == "off" then on = false
		elseif param == "" then on = not teleportation.blocks_all(name)
		else return false, "Usage: /tpblockall [on|off]" end
		teleportation.block_all(name, on)
		if on then
			teleportation.drop_requests(name)
			return true, "All teleport requests are blocked."
		end
		return true, "Teleport requests are allowed again" .. (#teleportation.blocked_names(name) > 0
			and " (except from the players you blocked)." or ".")
	end,
})

core.register_chatcommand("tpblocklist", {
	description = "Show who you block teleport requests from",
	func = function(name)
		local list = teleportation.blocked_names(name)
		local text = teleportation.blocks_all(name) and "All requests are blocked." or "Requests are allowed."
		if #list > 0 then text = text .. " Blocked players: " .. table.concat(list, ", ") end
		return true, text
	end,
})
