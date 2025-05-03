local lualine_require = require("lualine_require")
local M = lualine_require.require("lualine.component"):extend()

function M.update_status()
	return require("upower").get_status_text()
end

return M
