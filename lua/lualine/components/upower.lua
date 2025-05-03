local lualine_require = require("lualine_require")
local M = lualine_require.require("lualine.component"):extend()

function M.update_status()
	local icon = require("upower").get_status_icon()
	local text = require("upower").get_status_text()
	return icon .. text
end

return M
