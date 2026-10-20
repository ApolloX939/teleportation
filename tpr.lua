-- /tpr <player>: ask to teleport to a player. They get a window with Accept /
-- Deny (or /tpaccept, /tpdeny); no answer in time cancels the request.

local FORM = "teleportation:request:" -- formname .. requester

local pending = {} -- pending[target][requester] = { id, job }
local next_id = 0

local function timeout()
	return tonumber(core.settings:get("teleportation.request_timeout")) or 30
end

local function say(name, msg)
	core.chat_send_player(name, msg)
end

local function formspec(requester)
	return table.concat({
		"formspec_version[4]size[7.5,3.4]",
		"label[0.5,0.8;", core.formspec_escape(requester), " wants to teleport to you.]",
		"label[0.5,1.3;It expires in ", tostring(timeout()), " seconds.]",
		"button_exit[0.5,2;3,0.8;accept;Accept]",
		"button_exit[4,2;3,0.8;deny;Deny]",
	})
end

-- removes a request; true if there was one
local function remove(target, requester)
	local requests = pending[target]
	local req = requests and requests[requester]
	if not req then return false end
	req.job:cancel()
	requests[requester] = nil
	if next(requests) == nil then pending[target] = nil end
	core.close_formspec(target, FORM .. requester)
	return true
end

-- the request to answer: the named one, or the newest
local function pick(target, requester)
	local requests = pending[target]
	if not requests then return nil end
	if requester and requester ~= "" then
		return requests[requester] and requester or nil
	end
	local best, best_id
	for name, req in pairs(requests) do
		if not best_id or req.id > best_id then best, best_id = name, req.id end
	end
	return best
end

local function accept(target, requester)
	remove(target, requester)
	local from, to = core.get_player_by_name(requester), core.get_player_by_name(target)
	if not from or not to then
		say(target, requester .. " isn't online any more.")
		return
	end
	from:set_pos(to:get_pos())
	say(requester, target .. " accepted your request.")
	say(target, requester .. " teleported to you.")
end

local function deny(target, requester)
	remove(target, requester)
	say(requester, target .. " denied your request.")
	say(target, "Denied the request from " .. requester .. ".")
end

-- used by the blocking commands: drops (silently for the requester's side:
-- they're told it's no longer wanted) the requests a block makes pointless
function teleportation.drop_requests(target, requester)
	for name in pairs(pending[target] or {}) do
		if not requester or name == requester then
			remove(target, name)
			say(name, target .. " isn't accepting teleport requests.")
		end
	end
end

core.register_chatcommand("tpr", {
	params = "<player>",
	description = "Ask to teleport to a player",
	func = function(name, param)
		local target = param:trim()
		if target == "" then return false, "Usage: /tpr <player>" end
		if target == name then return false, "You can't teleport to yourself." end
		if not core.get_player_by_name(name) then return false, "You must be online." end
		if not core.get_player_by_name(target) then return false, target .. " isn't online." end
		if teleportation.is_blocked(target, name) then
			return false, target .. " isn't accepting teleport requests."
		end
		if pending[target] and pending[target][name] then
			return false, "You already asked " .. target .. "."
		end

		next_id = next_id + 1
		local req = { id = next_id }
		req.job = core.after(timeout(), function()
			-- still the same request
			if pending[target] and pending[target][name] == req then
				remove(target, name)
				say(name, "Your request to " .. target .. " timed out.")
				say(target, "The request from " .. name .. " timed out.")
			end
		end)
		pending[target] = pending[target] or {}
		pending[target][name] = req

		say(target, name .. " wants to teleport to you. /tpaccept " .. name .. " or /tpdeny " .. name
			.. " (" .. timeout() .. " seconds).")
		core.show_formspec(target, FORM .. name, formspec(name))
		return true, "Asked " .. target .. ". It expires in " .. timeout() .. " seconds."
	end,
})

core.register_chatcommand("tpaccept", {
	params = "[player]",
	description = "Accept a teleport request (the newest if no player is named)",
	func = function(name, param)
		local requester = pick(name, param:trim())
		if not requester then return false, "No request to accept." end
		accept(name, requester)
		return true
	end,
})

core.register_chatcommand("tpdeny", {
	params = "[player]",
	description = "Deny a teleport request (the newest if no player is named)",
	func = function(name, param)
		local requester = pick(name, param:trim())
		if not requester then return false, "No request to deny." end
		deny(name, requester)
		return true
	end,
})

core.register_chatcommand("tpcancel", {
	params = "[player]",
	description = "Cancel your teleport request (to a player, or all)",
	func = function(name, param)
		param = param:trim()
		local cancelled = 0
		for target, requests in pairs(pending) do
			if (param == "" or param == target) and requests[name] then
				remove(target, name)
				say(target, name .. " cancelled the request.")
				cancelled = cancelled + 1
			end
		end
		if cancelled == 0 then return false, "You have no request to cancel." end
		return true, "Cancelled."
	end,
})

core.register_on_player_receive_fields(function(player, formname, fields)
	if formname:sub(1, #FORM) ~= FORM then return end
	local target, requester = player:get_player_name(), formname:sub(#FORM + 1)
	if not (pending[target] and pending[target][requester]) then return true end
	if fields.accept then accept(target, requester)
	elseif fields.deny then deny(target, requester) end
	return true
end)

core.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	for target in pairs(pending) do
		if target == name then
			for requester in pairs(pending[target]) do
				remove(target, requester)
				say(requester, name .. " left.")
			end
		elseif pending[target][name] then
			remove(target, name)
			say(target, name .. " left; their request was cancelled.")
		end
	end
end)
