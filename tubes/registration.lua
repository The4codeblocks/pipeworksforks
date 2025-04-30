-- This file supplies the various kinds of pneumatic tubes
local S = minetest.get_translator("pipeworks")

local tubenodes = {}
pipeworks.tubenodes = tubenodes

minetest.register_alias("pipeworks:tube", "pipeworks:tube_000000")

-- now, a function to define the tubes

local REGISTER_COMPATIBILITY = true

local vti = {4, 3, 2, 1, 6, 5}

local default_plain = { "pipeworks_tube_plain.png" }

local texture_mt = {
	__index = function(table, key)
		local size, idx = #table, tonumber(key)
		if size > 0 then -- avoid endless loops with empty tables
			while idx > size do idx = idx - size end
			return table[idx]
		end
	end
}

-- This will remove any semi-transparent pixels
-- because that is still buggy in Minetest, force this as default
local texture_alpha_mode = minetest.features.use_texture_alpha_string_modes
	and "clip" or true

local box = {
    type = "connected",
    connect_top =    { -9/64,  9/64, -9/64, 9/64, 1/2,   9/64 },
    connect_bottom = { -9/64, -1/2,   -9/64, 9/64,-9/64, 9/64 },
    connect_front =  { -9/64, -9/64, -1/2,   9/64, 9/64,-9/64 },
    connect_back =   { -9/64, -9/64,  9/64, 9/64, 9/64, 1/2   },
    connect_left =   { -1/2,   -9/64, -9/64,-9/64, 9/64, 9/64 },
    connect_right =  {  9/64, -9/64, -9/64, 1/2,   9/64, 9/64 },
    fixed =          { -12/64, -12/64, -12/64, 12/64, 12/64, 12/64 }
}

local selbox = {
    type = "connected",
    connect_top =    { -10/64,  10/64, -10/64, 10/64, 1/2,   10/64 },
    connect_bottom = { -10/64, -1/2,   -10/64, 10/64,-10/64, 10/64 },
    connect_front =  { -10/64, -10/64, -1/2,   10/64, 10/64,-10/64 },
    connect_back =   { -10/64, -10/64,  10/64, 10/64, 10/64, 1/2   },
    connect_left =   { -1/2,   -10/64, -10/64,-10/64, 10/64, 10/64 },
    connect_right =  {  10/64, -10/64, -10/64, 1/2,   10/64, 10/64 },
    fixed =          { -13/64, -13/64, -13/64, 13/64, 13/64, 13/64 }
}

local register_one_tube = function(name, tname, dropname, desc, plain, _, _, _, inv, special, connects, style)
	plain = plain or default_plain
	setmetatable(plain, texture_mt)
	inv = inv or "pipeworks_tube_inv.png"

	table.insert(tubenodes, name)

	local nodedef = {
		description = desc,
		drawtype = "nodebox",
		tiles = plain,
		use_texture_alpha = texture_alpha_mode,
		sunlight_propagates = true,
		inventory_image = inv,
		wield_image = inv,
		wield_scale = {x = 1, y = 1, z = 0.01},
		paramtype = "light",
		selection_box = selbox,
		node_box = box,
		groups = {snappy = 3, tube = 1, tubedevice = 1, dig_generic = 4, axey=1, handy=1, pickaxey=1},
		is_ground_content = false,
		_mcl_hardness=0.8,
		_sound_def = {
			key = "node_sound_wood_defaults",
		},
		walkable = true,
		basename = name,
		connects_to = {"group:tubedevice","group:injector"},
		style = style,
		drop = string.format("%s_%s", name, dropname),
		tubelike = 1,
		tube = {
			connect_sides = {front = 1, back = 1, left = 1, right = 1, top = 1, bottom = 1},
			priority = 50
		},
		on_punch = function(pos, node, player, pointed)
			local playername = player:get_player_name()
			if minetest.is_protected(pos, playername) and not minetest.check_player_privs(playername, {protection_bypass=true}) then
				return minetest.node_punch(pos, node, player, pointed)
			end
			if pipeworks.check_and_wear_hammer(player) then
				local wieldname = player:get_wielded_item():get_name()
				pipeworks.logger(string.format("%s struck a tube at %s with %s to break it.", playername, minetest.pos_to_string(pos), wieldname))
				pipeworks.break_tube(pos)
			end
			return minetest.node_punch(pos, node, player, pointed)
		end,
						on_rotate = false,
		on_blast = function(pos, intensity)
			if not intensity or intensity > 1 + 3^0.5 then
				minetest.remove_node(pos)
				return {string.format("%s_%s", name, dropname)}
			end
			minetest.swap_node(pos, {name = "pipeworks:broken_tube_1"})
			pipeworks.scan_for_tube_objects(pos)
		end,
		check_for_pole = pipeworks.check_for_vert_tube,
		check_for_horiz_pole = pipeworks.check_for_horiz_tube,
		tubenumber = tonumber(tname)
	}

	if special == nil then special = {} end

	for key, value in pairs(special) do
		--if key == "after_dig_node" or key == "after_place_node" then
		--	nodedef[key.."_"] = value
		if key == "groups" then
			for group, val in pairs(value) do
				nodedef.groups[group] = val
			end
		elseif key == "tube" then
			for key, val in pairs(value) do
				nodedef.tube[key] = val
			end
		else
			nodedef[key] = pipeworks.table_recursive_replace(value, "#id", tname)
		end
	end

	local rname = string.format("%s_%s", name, tname)
	core.register_alias(rname, name)
	if not core.registered_nodes[name] then core.register_node(name, nodedef) end
end

local register_all_tubes = function(name, desc, plain, _, _, _, inv, special, old_registration)
	if old_registration then
		for xm = 0, 1 do
		for xp = 0, 1 do
		for ym = 0, 1 do
		for yp = 0, 1 do
		for zm = 0, 1 do
		for zp = 0, 1 do
			local connects = {}
			if xm == 1 then
				connects[#connects+1] = 1
			end
			if xp == 1 then
				connects[#connects+1] = 2
			end
			if ym == 1 then
				connects[#connects+1] = 3
			end
			if yp == 1 then
				connects[#connects+1] = 4
			end
			if zm == 1 then
				connects[#connects+1] = 5
			end
			if zp == 1 then
				connects[#connects+1] = 6
			end
			local tname = xm..xp..ym..yp..zm..zp
			register_one_tube(name, tname, "000000", desc, plain, nil, nil, nil, inv, special, connects, "old")
		end
		end
		end
		end
		end
		end
		pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = name.."_000000"
	else
		-- 6d tubes: uses only 10 nodes instead of 64, but the textures must be rotated
		local cconnects = {{}, {1}, {1, 2}, {1, 3}, {1, 3, 5}, {1, 2, 3}, {1, 2, 3, 5}, {1, 2, 3, 4}, {1, 2, 3, 4, 5}, {1, 2, 3, 4, 5, 6}}
		for index, connects in ipairs(cconnects) do
			register_one_tube(name, tostring(index), "1", desc, plain, nil, nil, nil, inv, special, connects, "6d")
		end
		if REGISTER_COMPATIBILITY then
			local cname = name.."_compatibility"
			minetest.register_node(cname, {
				drawtype = "airlike",
				style = "6d",
				basename = name,
				inventory_image = inv,
				wield_image = inv,
				paramtype = "light",
				sunlight_propagates = true,
				description = S("Pneumatic tube segment (legacy)"),
								groups = {not_in_creative_inventory = 1, tube_to_update = 1, tube = 1},
				is_ground_content = false,
				tube = {connect_sides = {front = 1, back = 1, left = 1, right = 1, top = 1, bottom = 1}},
				drop = name.."_1",
			})
			pipeworks.ui_cat_tube_list[#pipeworks.ui_cat_tube_list+1] = name.."_1"
			table.insert(tubenodes, cname)
			for xm = 0, 1 do
			for xp = 0, 1 do
			for ym = 0, 1 do
			for yp = 0, 1 do
			for zm = 0, 1 do
			for zp = 0, 1 do
				local tname = xm..xp..ym..yp..zm..zp
				minetest.register_alias(name.."_"..tname, cname)
			end
			end
			end
			end
			end
			end
		end
	end
end

pipeworks.register_tube = function(name, def, ...)
	if type(def) == "table" then
		register_all_tubes(name, def.description,
				def.plain, nil, nil, nil,
				def.inventory_image, def.node_def, def.no_facedir)
	else
		-- we assert to be the old function with the second parameter being the description
		-- function(name, desc, plain, noctrs, ends, short, inv, special, old_registration)
		assert(type(def) == "string", "invalid arguments to pipeworks.register_tube")
		register_all_tubes(name, def, ...)
	end
end


if REGISTER_COMPATIBILITY then
	minetest.register_abm({
		nodenames = {"group:tube_to_update"},
		interval = 1,
		chance = 1,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local minp = vector.subtract(pos, 1)
			local maxp = vector.add(pos, 1)
			if table.getn(minetest.find_nodes_in_area(minp, maxp, "ignore")) == 0 then
				pipeworks.scan_for_tube_objects(pos)
			end
		end
	})
end
