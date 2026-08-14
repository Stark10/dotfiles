local function fail(message)
	vim.api.nvim_err_writeln(message)
	vim.cmd("cquit 1")
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
		for _, name in ipairs(names) do
			local package = registry.get_package(name)
			if not package:is_installed() and not package:is_installing() then
				package:install()
			end
		end
		refreshed = true
	end)

	local complete = vim.wait(300000, function()
		if not refreshed then
			return false
		end
		if #failures > 0 then
			return true
		end
		for _, name in ipairs(names) do
			if not registry.get_package(name):is_installed() then
				return false
			end
		end
		return true
	end, 100)

	assert(complete, "Mason package installation timed out")
	assert(#failures == 0, "Mason package installation failed:\n" .. table.concat(failures, "\n"))
	print(("Mason packages ready (%d)"):format(#names))
end)

if not ok then
	fail(err)
else
	vim.cmd("qa")
end
