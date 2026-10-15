local function fail(message)
	vim.api.nvim_err_writeln(message)
	vim.cmd("cquit 1")
end

local function install_and_wait(registry, names, failures)
	for _, name in ipairs(names) do
		local package = registry.get_package(name)
		if not package:is_installed() and not package:is_installing() then
			package:install()
		end
	end

	local complete = vim.wait(300000, function()
		if #failures > 0 then
			return true
		end
		for _, name in ipairs(names) do
			local package = registry.get_package(name)
			if package:is_installing() or not package:is_installed() then
				return false
			end
		end
		return true
	end, 100)

	assert(complete, "Mason package installation timed out")
	assert(#failures == 0, "Mason package installation failed:\n" .. table.concat(failures, "\n"))
end

local ok, err = pcall(function()
	require("lazy").load({ plugins = { "mason.nvim" } })

	local registry = require("mason-registry")
	local names = LazyVim.opts("mason.nvim").ensure_installed or {}
	local refreshed = false
	local failures = {}

	registry:on("package:install:failed", function(package, install_error)
		failures[#failures + 1] = package.name .. ": " .. vim.inspect(install_error)
	end)

	registry.refresh(function()
		refreshed = true
	end)

	assert(vim.wait(300000, function()
		return refreshed
	end, 100), "Mason registry refresh timed out")
	install_and_wait(registry, names, failures)
	print(("Mason packages ready (%d)"):format(#names))

	-- mason-lspconfig deliberately skips automatic installation in headless mode.
	-- Load the normal LazyVim LSP config, then install the exact server list it selected.
	require("lazy").load({ plugins = { "nvim-lspconfig" } })
	local server_names = require("mason-lspconfig.settings").current.ensure_installed
	local mappings = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
	local lsp_packages = {}
	for _, server in ipairs(server_names) do
		local name = server:match("^[^@]+")
		local package = mappings[name]
		if package then
			lsp_packages[#lsp_packages + 1] = package
		end
	end
	install_and_wait(registry, lsp_packages, failures)
	print(("Mason language servers ready (%d)"):format(#lsp_packages))

	require("lazy").load({ plugins = { "nvim-treesitter" } })
	local treesitter = require("nvim-treesitter")
	local parser_names = LazyVim.opts("nvim-treesitter").ensure_installed or {}
	treesitter.install(parser_names, { summary = true }):wait(300000)

	local installed = {}
	for _, name in ipairs(treesitter.get_installed()) do
		installed[name] = true
	end
	local missing = vim.tbl_filter(function(name)
		return not installed[name]
	end, parser_names)
	assert(#missing == 0, "Tree-sitter parser installation failed: " .. table.concat(missing, ", "))
	print(("Tree-sitter parsers ready (%d)"):format(#parser_names))
end)

if not ok then
	fail(err)
else
	vim.cmd("qa")
end
