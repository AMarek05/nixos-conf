-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- {
  --   'nvim-neorg/neorg',
  --   lazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
  --   version = '*', -- Pin Neorg to the latest stable release
  --   config = function()
  --     require('neorg').setup {
  --       load = {
  --         ['core.defaults'] = {},
  --         ['core.concealer'] = {},
  --         ['core.dirman'] = {
  --           config = {
  --             workspaces = {
  --               notes = '~/gdrive/Notes/neorg/',
  --             },
  --             default_workspace = 'notes',
  --           },
  --         },
  --       },
  --     }
  --   end,
  -- },
  {
    'aserowy/tmux.nvim',
    lazy = false,
    version = '*',
    config = function()
      require('tmux').setup {
        copy_sync = {
          redirect_to_clipboard = true,
        },
      }
    end,
  },
  {
    'farmergreg/vim-lastplace',
  },
  {
    'tpope/vim-obsession',
  },
}
