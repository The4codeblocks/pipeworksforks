pipeworks.chests = {}

-- register a chest to connect with pipeworks tubes.
-- will autoconnect to tubes and add tube inlets to the textures
-- it is highly recommended to allow the user to change the "splitstacks" int (1 to enable) in the node meta
-- but that can't be done by this function

-- @param override: additional overrides, such as stuff to modify the node formspec
-- @param connect_sides: which directions the chests shall connect to
function pipeworks.override_chest(chestname, override, connect_sides)
	local old_def = minetest.registered_nodes[chestname]
	local nodebox_connection = {}

	local tube_entry = "^pipeworks_tube_connection_wooden.png"
	override.tiles = override.tiles or old_def.tiles
	-- expand the tiles table if it has been shortened
	if #override.tiles < 6 then
		for i = #override.tiles, 6 do
			override.tiles[i] = override.tiles[#override.tiles]
		end
	end
	-- add inlets to the sides that connect to tubes
	local tile_directions = {"top", "bottom", "right", "left", "back", "front"}
	for i, direction in ipairs(tile_directions) do
		if connect_sides[direction] then
			table.insert( nodebox_connection, direction )
			if type(override.tiles[i]) == "string" then
				override.tiles[i] = override.tiles[i] .. tube_entry
			elseif type(override.tiles[i]) == "table" and not override.tiles[i].animation then
				override.tiles[i].name = override.tiles[i].name .. tube_entry
			end
		end
	end

	override.tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("main", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if meta:get_int("splitstacks") == 1 then
				stack = stack:peek_item(1)
			end
			return inv:room_for_item("main", stack)
		end,
		input_inventory = "main",
		connect_sides = connect_sides
	}

	-- Add the extra groups
	override.groups = override.groups or old_def.groups or {}
	override.groups.tubedevice = 1
	override.groups.tubedevice_receiver = 1
	override.connect_sides = nodebox_connection

	minetest.override_item(chestname, override)
	pipeworks.chests[chestname] = true
end
