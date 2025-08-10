local plugin = require("make.plugin")

vim.api.nvim_create_user_command("Make", plugin.run_command, {
	nargs = 1,
	complete = plugin.find_targets,
})

return plugin
