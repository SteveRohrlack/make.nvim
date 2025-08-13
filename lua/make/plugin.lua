local Path = require("plenary.path")

local MAX_INT = 2 ^ 53 - 1
local LANG_MAKE = "make"

local function is_eof(any)
	return #any == 1 and any[1] == ""
end

local function is_makefile()
	return vim.bo.filetype == LANG_MAKE
end

local function parse_make_target(any)
	return any:match("^([%w-_]+):")
end

local function get_treesitter_root_node(bufnr, lang)
	if not vim.treesitter then
		return nil
	end

	local parser = vim.treesitter.get_parser(bufnr, lang)
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		return nil
	end

	return tree:root()
end

-- deprecated, maybe use as fallback when treesitter is not available
local function find_buffer_targets()
	local targets = {}

	local bufnr = vim.api.nvim_get_current_buf()
	local last_line = vim.api.nvim_buf_line_count(bufnr)
	local file_lines = vim.api.nvim_buf_get_lines(bufnr, 0, last_line, true)

	local iterate = function(line_nr, line)
		local target = parse_make_target(line)
		if not target then
			return
		end

		targets[line_nr] = target
	end

	for i, line in ipairs(file_lines) do
		iterate(i, line)
	end

	return targets
end

local function find_targets(bufnr)
	local root = get_treesitter_root_node(bufnr, LANG_MAKE)
	if not root then
		return {}
	end

	local ruleType = "rule"
	local query = vim.treesitter.query.parse(
		LANG_MAKE,
		[[
      (rule) @rule
    ]]
	)

	local targets = {}
	for id, node in query:iter_captures(root, bufnr) do
		local type = query.captures[id]

		if type == ruleType then
			local starts_at, _, ends_at, _ = node:range()

			for child in node:iter_children() do
				if child:type() == "targets" then
					local text = vim.treesitter.get_node_text(child, bufnr)
					for target in text:gmatch("[^ ]+") do
						table.insert(targets, {
							line_nr = starts_at + 1,
							end_line_nr = ends_at,
							name = target,
						})
					end
				end
			end
		end
	end

	return targets
end

-- deprecated, maybe use as fallback when treesitter is not available
local function find_nearest_buffer_target(targets)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current_line, _ = unpack(cursor)

	local closest_to_cursor = MAX_INT
	local nearest_target = {}
	local target_line = 0

	local function iterate(line_nr, target)
		local diff = math.abs(current_line - line_nr)
		if diff < closest_to_cursor then
			closest_to_cursor = diff
			nearest_target = target
			target_line = line_nr
		end
		if diff == 0 then
			return
		end
	end

	for _, target in ipairs(targets) do
		iterate(target.line_nr, target.name)
	end

	return nearest_target, target_line
end

local function find_nearest_target(targets, reference_line_nr)
	for _, target in ipairs(targets) do
		if reference_line_nr >= target.line_nr and reference_line_nr <= target.end_line_nr then
			return target.name, target.line_nr
		end
	end
end

local function get_cursor_line_nr()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_line_nr, _ = unpack(cursor)
	return cursor_line_nr
end

local M = {}

function M.setup() end

function M.run_nearest()
	if not is_makefile() then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local targets = find_targets(bufnr)

	local nearest_target, _ = find_nearest_target(targets, get_cursor_line_nr())
	if not nearest_target then
		vim.notify("no target found 🤷", vim.log.levels.INFO, {
			title = "make.nvim",
		})
		return
	end

	M.run_target(nearest_target)
end

function M.run_selected(opts)
	M.run_target(opts.fargs[1])
end

function M.run_target(target)
	if not target then
		return
	end

	local cmd = "make " .. target
	local didErr = false

	vim.fn.jobstart(cmd, {
		stderr_buffered = true,
		on_stderr = function(_, data)
			if is_eof(data) then
				return
			end
			didErr = true
			vim.notify(data[1], vim.log.levels.ERROR, {
				title = cmd,
			})
		end,
		on_exit = function()
			if didErr then
				return
			end
			vim.notify("✅🔔📯", vim.log.levels.INFO, {
				title = cmd,
			})
		end,
	})
end

-- TODO: use treesitter to parse Makefile
function M.find_targets(searchTerm)
	local searchResults = {}
	local file_path = Path:new("Makefile")

	if not file_path:exists() then
		return
	end

	local iterator = function(line)
		local target = parse_make_target(line)
		if not target then
			return
		end

		if #searchTerm == 0 then
			table.insert(searchResults, target)
			return
		end

		local searchMatch = not (string.find(target, searchTerm) == nil)
		if searchMatch then
			table.insert(searchResults, target)
		end
	end

	for line in file_path:iter() do
		iterator(line)
	end

	return searchResults
end

function M.decorate_makefile(opts)
	if not opts.file or not is_makefile() then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()

	local targets = find_targets(bufnr)
	local _, nearest_target_line_nr = find_nearest_target(targets, get_cursor_line_nr())

	vim.fn.sign_unplace("MakeTarget", {
		buffer = bufnr,
	})

	for _, target in ipairs(targets) do
		local name = "MakeTarget"
		if target.line_nr == nearest_target_line_nr then
			name = "MakeTargetHighlight"
		end
		vim.fn.sign_place(target.line_nr, "MakeTarget", name, bufnr, {
			lnum = target.line_nr,
		})
	end
end

return M
