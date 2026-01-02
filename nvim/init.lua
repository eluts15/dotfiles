-- Tell Lua language server that 'vim' is a global
---@diagnostic disable-next-line: undefined-global
local vim = vim

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)


-- Options
vim.opt.completeopt = {'menuone', 'noselect', 'noinsert'}
vim.opt.shortmess = vim.opt.shortmess + { c = true}
vim.api.nvim_set_option('updatetime', 300)
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = 'yes'
vim.opt.wrap = false  -- Don't wrap lines
vim.opt.display = 'lastline'  -- Show as much of last line as possible instead of @
vim.opt.splitright = true  -- Vertical splits open to the right
vim.opt.splitbelow = true  -- Horizontal splits open below (optional but recommended)
vim.opt.mouse = 'a'  -- Enable mouse support in all modes
-- vim.opt.scrolloff = 15  -- Keep 15 lines visible above/below cursor

-- Treesitter folding
-- Treesitter folding (disabled by default)
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldenable = false  -- Start with folds open
vim.opt.foldlevel = 99  -- Open all folds by default
vim.opt.mouse = 'a'  -- Enable mouse support in all modes


-- Setup lazy.nvim
require("lazy").setup({
  -- Mason
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        }
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require('mason-lspconfig').setup({})
    end,
  },

  -- LSP
  "neovim/nvim-lspconfig",

  -- Rust
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false,
    ft = { 'rust' },
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/vim-vsnip",
    },
  },

  -- Colorscheme
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        terminal_colors = true,
        undercurl = true,
        underline = false,
        bold = true,
        italic = {
          strings = true,
          emphasis = true,
          comments = true,
          operators = false,
          folds = true,
        },
        strikethrough = true,
        invert_selection = false,
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        inverse = false,
        contrast = "",
        palette_overrides = {},
        overrides = {},
        dim_inactive = false,
        transparent_mode = false,
      })

      vim.cmd("colorscheme gruvbox")
      -- Fix all highlights after colorscheme loads
      vim.cmd([[
        highlight! LineNr guifg=#928374 guibg=NONE
        highlight! CursorLineNr guifg=#fabd2f guibg=NONE gui=bold
        highlight! SignColumn guibg=NONE
        
        highlight! NormalFloat guifg=#ebdbb2 guibg=#282828
        highlight! FloatBorder guifg=#928374 guibg=#282828
        
        highlight! DiagnosticError guifg=#fb4934 guibg=NONE
        highlight! DiagnosticWarn guifg=#fabd2f guibg=NONE
        highlight! DiagnosticInfo guifg=#83a598 guibg=NONE
        highlight! DiagnosticHint guifg=#8ec07c guibg=NONE
        
        highlight! link DiagnosticFloatingError NormalFloat
        highlight! link DiagnosticFloatingWarn NormalFloat
        highlight! link DiagnosticFloatingInfo NormalFloat
        highlight! link DiagnosticFloatingHint NormalFloat
      ]])
    end,
  },
})

-- Rust Setup with rustaceanvim
--vim.g.rustaceanvim = {
--  tools = {},
--  server = {
--    on_attach = function(client, bufnr)
--      vim.keymap.set("n", "<C-space>", function()
--        vim.cmd.RustLsp({'hover', 'actions'})
--      end, { buffer = bufnr, desc = "Rust hover actions" })
--      vim.keymap.set("n", "<Leader>a", function()
--        vim.cmd.RustLsp('codeAction')
--      end, { buffer = bufnr, desc = "Rust code actions" })
--    end,
--    default_settings = {
--      ['rust-analyzer'] = {},
--    },
--  },
--  dap = {},
--}

-- Rust Setup with rustaceanvim
vim.g.rustaceanvim = {
  tools = {},
  server = {
    on_attach = function(client, bufnr)
      vim.keymap.set("n", "<C-space>", function()
        vim.cmd.RustLsp({'hover', 'actions'})
      end, { buffer = bufnr, desc = "Rust hover actions" })
      vim.keymap.set("n", "<Leader>a", function()
        vim.cmd.RustLsp('codeAction')
      end, { buffer = bufnr, desc = "Rust code actions" })
    end,
    default_settings = {
      ['rust-analyzer'] = {
        completion = {
          callable = {
            snippets = "fill_arguments",
          },
          postfix = {
            enable = false,
          },
        },
      },
    },
  },
  dap = {},
}

-- Run rustfmt on save for Rust files
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- LSP Diagnostics Configuration
vim.diagnostic.config({
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.HINT] = '',
      [vim.diagnostic.severity.INFO] = '',
    },
  },
  update_in_insert = true,
  underline = true,
  severity_sort = false,
  float = {
    border = 'rounded',
    source = 'always',
    header = '',
    prefix = '',
    focusable = false,
    style = 'minimal',
    format = function(diagnostic)
      return string.format("%s", diagnostic.message)
    end,
  },
})

-- Show diagnostics on cursor hold
vim.cmd([[
autocmd CursorHold * lua vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
]])

-- Completion Plugin Setup
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-S-f>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    })
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp', keyword_length = 3, max_item_count = 20 },
  }, {
    { name = 'path' },
    { name = 'nvim_lua', keyword_length = 2},
    { name = 'buffer', keyword_length = 2 },
    { name = 'vsnip', keyword_length = 2 },
    { name = 'calc'},
  }),
  sorting = {
    comparators = {
      cmp.config.compare.offset,
      cmp.config.compare.exact,
      cmp.config.compare.score,
      cmp.config.compare.recently_used,
      cmp.config.compare.locality,
      cmp.config.compare.kind,
      cmp.config.compare.sort_text,
      cmp.config.compare.length,
      cmp.config.compare.order,
    },
  },
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    fields = {'menu', 'abbr', 'kind'},
    format = function(entry, item)
      local menu_icon = {
        nvim_lsp = 'λ',
        vsnip = '⋗',
        buffer = 'Ω',
        path = '🖫',
      }
      item.menu = menu_icon[entry.source.name]
      return item
    end,
  },
})

-- LSP signature help (shows function parameters as you type)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = "rounded",
    focusable = false,
  }
)
