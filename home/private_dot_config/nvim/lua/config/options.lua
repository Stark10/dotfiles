-- Put swap files in a dedicated directory to avoid .swp clutter.
vim.opt.directory = vim.fn.stdpath("state") .. "/swap//"
