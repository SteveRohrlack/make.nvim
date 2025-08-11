local plugin = require("make.plugin")

vim.fn.sign_define("MakeTarget", {
	text = "󰐊",
	texthl = "DiagnosticSignHint",
})

vim.fn.sign_define("MakeTargetHighlight", {
	text = "󰐊",
	texthl = "DiagnosticSignWarn",
})

vim.api.nvim_create_user_command("Make", plugin.run_selected, {
	nargs = 1,
	complete = plugin.find_targets,
})

vim.api.nvim_create_user_command("MakeNearest", plugin.run_nearest, {})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "Makefile",
	callback = plugin.decorate_makefile,
})

vim.api.nvim_create_autocmd("CursorMoved", {
	pattern = "Makefile",
	callback = plugin.decorate_makefile,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "Makefile",
	callback = plugin.decorate_makefile,
})

return plugin
