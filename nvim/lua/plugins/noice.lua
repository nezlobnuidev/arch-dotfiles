return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.cmdline = vim.tbl_extend("force", opts.cmdline or {}, {
        view = "cmdline_popup",
      })
      opts.presets = vim.tbl_extend("force", opts.presets or {}, {
        command_palette = false,
      })
      opts.views = vim.tbl_deep_extend("force", opts.views or {}, {
        cmdline_popup = {
          position = { row = "50%", col = "50%" },
          size = { width = 60, height = "auto" },
          border = { style = "rounded" },
        },
      })
      return opts
    end,
  },
}
