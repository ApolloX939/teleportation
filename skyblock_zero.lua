-- Skyblock: Zero: the world is void, so a random column in a box almost never
-- has anything to stand on. Its land is the planets (sbz_api.planets.area, an
-- AreaStore of cubes holding { type, radius }, each a sphere around the cube's
-- centre): /rtp picks a planet that touches the box and a point on its
-- surface. The box is made larger (teleportation.sbz_range_factor, 1.5) to
-- touch more planets. Without any planet in the box, the plain search runs.

local plain = teleportation.pick_column

local function setting_num(key, default)
	return tonumber(core.settings:get("teleportation." .. key)) or default
end

local function planet_store()
	if core.settings:get_bool("teleportation.sbz_planets", true) == false then return end
	local planets = rawget(_G, "sbz_api") and sbz_api.planets
	return planets and planets.area
end

function teleportation.pick_column(o, rx, ry, rz)
	local store = planet_store()
	if not store then return plain(o, rx, ry, rz) end

	local f = setting_num("sbz_range_factor", 1.5)
	local found = store:get_areas_in_area(
		vector.new(o.x - rx * f, o.y - ry * f, o.z - rz * f),
		vector.new(o.x + rx * f, o.y + ry * f, o.z + rz * f), true, true, true)
	local list = {}
	for _, area in pairs(found) do list[#list + 1] = area end
	if #list == 0 then return plain(o, rx, ry, rz) end

	local area = list[math.random(#list)]
	local radius = (core.deserialize(area.data) or {})[2]
	if not radius then return plain(o, rx, ry, rz) end
	local center = vector.divide(vector.add(area.min, area.max), 2)

	-- a point of the planet's disc (not its very edge, where the ground is
	-- almost vertical), and the band around the surface above it
	local angle, dist = math.random() * 2 * math.pi, 0.95 * radius * math.sqrt(math.random())
	local dx, dz = math.cos(angle) * dist, math.sin(angle) * dist
	local top = center.y + math.sqrt(math.max(0, radius * radius - dist * dist))
	return {
		x = math.floor(center.x + dx),
		z = math.floor(center.z + dz),
		ymin = math.floor(top - 80),
		ymax = math.floor(top + 60),
		highest = true,
	}
end
