if not SmartCoverPeeking then

	SmartCoverPeeking = {}
	SmartCoverPeeking.required = {}
	SmartCoverPeeking.mod_path = ModPath
	SmartCoverPeeking.save_path = SavePath .. "SmartCoverPeeking.json"
	SmartCoverPeeking.settings = {
		trigger_distance = 75,
		sticky_distance = 50,
		continuous_trigger = false
	}

	local data = io.file_is_readable(SmartCoverPeeking.save_path) and io.load_as_json(SmartCoverPeeking.save_path)
	if data then
		for k, v in pairs(data) do
			if type(SmartCoverPeeking.settings[k]) == type(v) then
				SmartCoverPeeking.settings[k] = v
			end
		end
	end

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitKillFeed", function(loc)
		if HopLib then
			HopLib:load_localization(SmartCoverPeeking.mod_path .. "loc/", loc)
		else
			loc:load_localization_file(SmartCoverPeeking.mod_path .. "loc/english.txt")
		end
	end)

	Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusSmartCoverPeeking", function(menu_manager, nodes)
		local menu_id_main = "SmartCoverPeekingMenu"
		local sticky_distance

		MenuHelper:NewMenu(menu_id_main)

		function MenuCallbackHandler:SmartCoverPeeking_value(item)
			SmartCoverPeeking.settings[item:name()] = item:value()
		end

		function MenuCallbackHandler:SmartCoverPeeking_continuous_trigger(item)
			SmartCoverPeeking.settings[item:name()] = item:value() == "on"
			sticky_distance:set_enabled(SmartCoverPeeking.settings.continuous_trigger)
		end

		function MenuCallbackHandler:SmartCoverPeeking_save()
			io.save_as_json(SmartCoverPeeking.settings, SmartCoverPeeking.save_path)
		end

		MenuHelper:AddSlider({
			id = "trigger_distance",
			title = "menu_scp_trigger_distance",
			desc = "menu_scp_trigger_distance_desc",
			callback = "SmartCoverPeeking_value",
			value = SmartCoverPeeking.settings.trigger_distance,
			min = 50,
			max = 150,
			step = 10,
			show_value = true,
			display_precision = 0,
			menu_id = menu_id_main,
			priority = 3
		})

		MenuHelper:AddDivider({
			size = 8,
			menu_id = menu_id_main,
			priority = 2
		})

		MenuHelper:AddToggle({
			id = "continuous_trigger",
			title = "menu_scp_continuous_trigger",
			desc = "menu_scp_continuous_trigger_desc",
			callback = "SmartCoverPeeking_continuous_trigger",
			value = SmartCoverPeeking.settings.continuous_trigger,
			menu_id = menu_id_main,
			priority = 1
		})

		sticky_distance = MenuHelper:AddSlider({
			id = "sticky_distance",
			title = "menu_scp_sticky_distance",
			desc = "menu_scp_sticky_distance_desc",
			callback = "SmartCoverPeeking_value",
			value = SmartCoverPeeking.settings.sticky_distance,
			disabled = not SmartCoverPeeking.settings.continuous_trigger,
			min = 0,
			max = 100,
			step = 10,
			show_value = true,
			display_precision = 0,
			menu_id = menu_id_main,
			priority = 0
		})

		nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { back_callback = "SmartCoverPeeking_save" })
		MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "menu_scp")
	end)

end

if RequiredScript and not SmartCoverPeeking.required[RequiredScript] then

	local fname = SmartCoverPeeking.mod_path .. RequiredScript:gsub(".+/(.+)", "lua/%1.lua")
	if io.file_is_readable(fname) then
		dofile(fname)
	end

	SmartCoverPeeking.required[RequiredScript] = true

end
