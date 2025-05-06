local normal = {
	fullycharged = "󱊣 ",
	high = "󱊣 ",
	medium = "󱊢 ",
	low = "󱊡 ",
	reallylow = "󱃍 ",
}

local charging = {
	fullycharged = "󰂅 ",
	high = "󱊦 ",
	medium = "󱊥 ",
	low = "󱊤 ",
	reallylow = "󰢟 ",
}

local levels = { --if above
	fullycharged = 100,
	high = 66,
	medium = 33,
	low = 10,
	reallylow = 0,
}

return {
	debug = false,

	timer_initial_delay_seconds = 10,
	--upower updates every 30 seconds
	timer_refresh_seconds_normal = 30,
	timer_refresh_seconds_charging = 30,

	timer_anim_update_ms = 1000,
	timer_anim_max_percentage = 299,

	power_levels = levels,

	icons_battery_normal = normal,
	icons_battery_charging = charging,
	icon_battery_missing = "󱉞 ",

	--alerts, and also used by the "is below" bool functions
	alert_battery_level_high = 80,
	alert_battery_level_low = 20,
	alert_battery_level_critical = 10,
}
