local M = {}

function M.check()
	vim.health.start("Checking if upower can be called")
	if os.execute("upower -v") == 0 then
		vim.health.ok("upower available")
	else
		vim.health.error("upower not available.  Install with apt install upower")
	end
end

return M
