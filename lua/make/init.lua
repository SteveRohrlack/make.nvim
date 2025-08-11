local plugin = require("make.plugin")

vim.api.nvim_create_user_command("Make", plugin.run_selected, {
	nargs = 1,
	complete = plugin.find_targets,
})

vim.api.nvim_create_user_command("MakeNearest", plugin.run_nearest, {})

return plugin
