local M = {}

local notify_opts = { title = "Battery Info", timeout = 10000 }

local upower_enumerate_devices = "upower -e"
local upower_device_info = "upower -i "

local config = require("upower.config")

local max_battery_samples = 10
local min_battery_samples = 1

local state = {
	has_battery = true,
	device_string = "", -- The device id string that upower uses to identify it
	charging = false,
	percentage = 0,
	previous_percentage = 0,
	latest_time_remaining = 0,
	battery_samples = {},
	average_time_remaining = 0,
	anim_state = 0,
	anim_icon = "",
	status_icon = "",
	status_text = "",
}

function M.setup(opts)
	for i, v in pairs(opts) do
		config[i] = v
	end
end

function M.has_battery()
	return state.has_battery
end

local function make_list(text)
	local len = string.len(text)
	local index = 1
	local items = {}
	for i = 1, len, 1 do
		local s = string.sub(text, i, i)
		if s == "\n" then
			index = index + 1
		else
			if items[index] == nil then
				items[index] = ""
			end
			items[index] = items[index] .. s
		end
	end
	return items
end

local function enumerate_devices()
	local handle = io.popen(upower_enumerate_devices)
	local result = handle:read("*a")
	handle:close()

	local devicelist = make_list(result)
	for i, v in ipairs(devicelist) do
		if string.find(v, "battery") then
			state.device_string = v
		end
	end
	if state.device_string == "" then
		state.has_battery = false
		vim.notify("No battery detected", vim.log.levels.INFO, notify_opts)
	end
end

local function handle_alerts()
	if state.has_battery then
		if (state.percentage == 100) and (state.previous_percentage ~= 100) then
			vim.notify("Battery is fully charged", vim.log.levels.INFO, notify_opts)
		end
		if
			(state.percentage >= config.alert_battery_level_high)
			and (state.previous_percentage < config.alert_battery_level_high)
		then
			vim.notify("Battery level high", vim.log.levels.INFO, notify_opts)
		end
		if
			(state.percentage <= config.alert_battery_level_low)
			and (state.previous_percentage > config.alert_battery_level_low)
		then
			vim.notify("Battery level low", vim.log.levels.WARN)
		end
		-- critical alert every time this runs, not just when first entering the critical range
		if state.percentage <= config.alert_battery_level_critical then
			vim.notify("Battery level critical!", vim.log.levels.ERROR)
		end
	end
end

local function update_state()
	local handle = io.popen(upower_device_info .. state.device_string)
	local result = handle:read("*a")
	handle:close()

	state.previous_percentage = state.percentage

	local resultstable = make_list(result)
	state.percentage = 0
	local found_discharging = false

	if not state.has_battery then
		state.charging = false
	end

	if config.debug then
		state.has_battery = true
		state.percentage = math.random(0, 100)
		state.charging = true
	else
		if state.has_battery then
			for i, v in ipairs(resultstable) do
				if string.find(v, "percentage") then
					local pos = string.find(v, "%d") or 0
					local per = "" -- = string.sub(v, pos)
					local e = string.find(v, "%%") - 1
					per = string.sub(v, pos, e)
					state.percentage = tonumber(per)
				end
				--note: upower updates every 30 seconds
				if string.find(v, "state:") and (string.find(v, "discharging")) then
					found_discharging = true
				end

				if string.find(v, "time to empty:") then
					state.latest_time_remaining = 0
					local pos = string.find(v, "%d") or 0
					local e = string.find(v, " hours")
					if e ~= nil then
						local t = string.sub(v, pos, e - 1)
						state.latest_time_remaining = tonumber(t)
					end

					--update array size
					local asize = #state.battery_samples
					--resize if not full
					if asize < max_battery_samples then
						table.insert(state.battery_samples, 0)
						asize = asize + 1
					end

					-- shift items down list
					for j = asize, 2, -1 do
						state.battery_samples[j] = state.battery_samples[j - 1]
					end
					-- store latest in position 1
					state.battery_samples[1] = state.latest_time_remaining
					-- calculate current averages
					local average = 0
					for j = 1, asize do
						average = average + state.battery_samples[j]
					end
					state.average_time_remaining = average / asize
				end
			end

			--start anim timer if it wasn't previously charging
			if not state.charging then
				if not found_discharging then
					vim.defer_fn(M.timer_anim, config.timer_anim_update_ms)
				end
			end
			state.charging = not found_discharging

			if state.charging then
				-- start over once charging is done
				state.battery_samples = {}
			end
		end
	end
end

local function update_status()
	if state.has_battery then
		local levels = config.power_levels
		local p = state.percentage
		local icons = config.icons_battery_normal

		local icon = icons.reallylow
		if p >= levels.low then
			icon = icons.low
		end
		if p >= levels.medium then
			icon = icons.medium
		end
		if p >= levels.high then
			icon = icons.high
		end
		if p >= levels.fullycharged then
			icon = icons.fullycharged
		end

		if state.charging then
			icon = state.anim_icon
		end

		local s = state.percentage .. "%%"
		if state.charging and (state.percentage == 100) then
			s = "Fully Charged"
		end
		if config.debug then
			s = s .. " DEBUG MODE"
		end

		-- print if not on charger, and only if there are enough samples taken
		if (not state.charging) and (#state.battery_samples >= min_battery_samples) then
			local hours = math.floor(state.average_time_remaining)
			local minsfrac = state.average_time_remaining % 1
			local mins = minsfrac * 60
			s = s .. " (" .. hours .. "h" .. string.format("%.0f", mins) .. "m)"
		end

		state.status_icon = icon
		state.status_text = s
	else
		state.status_icon = config.icon_battery_missing
		state.status_text = "No Battery Detected"
	end
end

function M.timer_anim()
	if state.anim_state == 0 then
		state.anim_icon = config.icons_battery_charging.reallylow
	end
	if state.anim_state == 1 then
		state.anim_icon = config.icons_battery_charging.low
	end
	if state.anim_state == 2 then
		state.anim_icon = config.icons_battery_charging.medium
	end
	if state.anim_state >= 3 then
		state.anim_icon = config.icons_battery_charging.high
	end

	state.anim_state = state.anim_state + 1
	if state.anim_state > 5 then
		state.anim_state = 0
	end

	if state.percentage > 99 then
		state.anim_icon = config.icons_battery_charging.fullycharged
	end

	update_status()

	if state.charging then
		vim.defer_fn(M.timer_anim, config.timer_anim_update_ms)
	end
end

function M.timer_loop()
	update_state()
	handle_alerts()
	update_status()
	if state.has_battery then
		local t = config.timer_refresh_seconds_normal
		if state.charging then
			t = config.timer_refresh_seconds_charging
		end
		if config.debug then
			vim.defer_fn(M.timer_loop, 5000)
		else
			vim.defer_fn(M.timer_loop, t * 1000)
		end
	else
		--if no battery wipe the status text and never loop
		state.status_text = ""
		state.status_icon = ""
	end
end

function M.init()
	enumerate_devices()
	--	update_state()
	--	update_status()
	--	vim.defer_fn(M.timer_loop, config.timer_initial_delay_seconds * 1000)
	M.timer_loop()
end

function M.get_status_icon()
	return state.status_icon
end

function M.get_status_text()
	return state.status_text
end

function M.is_below_level_low()
	return state.percentage <= config.alert_battery_level_low
end

function M.is_below_level_critical()
	return state.percentage <= config.alert_battery_level_critical
end

function M.is_charging()
	return state.charging
end

M.init()

return M
