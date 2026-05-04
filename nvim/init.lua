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

-- Treesitter folding (disabled by default)
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
vim.opt.foldenable = false  -- Start with folds open
vim.opt.foldlevel = 99  -- Open all folds by default


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
      "hrsh7th/cmp-vsnip",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/vim-vsnip",
    },
  },

  -- Signature help — auto-shows parameter hints inside function calls,
  -- and lets you manually toggle with Shift+k
  {
    "ray-x/lsp_signature.nvim",
    event = "LspAttach",
    config = function()
      require("lsp_signature").setup({
        bind          = true,
        handler_opts  = { border = "rounded" },
        hint_enable   = false,   -- no inline virtual-text hint
        floating_window = true,
        floating_window_above_cur_line = true,
        toggle_key    = "<S-k>",
        toggle_key_flip_floatwin_setting = true,
        select_signature_key = "<C-n>",  -- cycle overloads
      })
    end,
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

-- ─── Rust ────────────────────────────────────────────────────────────────────

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

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.rs",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

-- ─── Go ──────────────────────────────────────────────────────────────────────
--
-- Requires: gopls   (go install golang.org/x/tools/gopls@latest)
--           gofumpt (go install mvdan.cc/gofumpt@latest)
--
-- Neovim 0.11 ships a built-in lsp client with vim.lsp.config / vim.lsp.enable.
-- nvim-lspconfig is only needed for the helper utilities (e.g. root detection
-- helpers); the actual server lifecycle is managed by the new built-in API.

local capabilities = require('cmp_nvim_lsp').default_capabilities()

vim.lsp.config('gopls', {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  -- 0.11 uses root_markers instead of root_dir
  root_markers = { 'go.work', 'go.mod', '.git' },
  capabilities = capabilities,
  on_attach = function(client, bufnr)
    -- Go-specific keymaps (supplement the global ones set further below)
    vim.keymap.set("n", "<Leader>gi", function()
      vim.lsp.buf.implementation()
    end, { buffer = bufnr, desc = "Go to implementation" })
  end,
  settings = {
    gopls = {
      analyses = {
        unusedparams  = true,
        shadow        = true,
        unusedwrite   = true,
        useany        = true,
        nilness       = true,
      },
      staticcheck       = true,
      gofumpt           = true,
      -- NOTE: inlay hints are NOT a gopls setting — they are requested by the
      -- client via vim.lsp.inlay_hint. Putting them here causes the
      -- "unexpected gopls setting" warning. Toggle with <Leader>ih instead.
      codelenses = {
        gc_details     = true,   -- show memory / escape analysis
        generate       = true,   -- run go generate
        regenerate_cgo = true,
        run_govulncheck= true,
        test           = true,
        tidy           = true,
        upgrade_dependency = true,
        vendor         = true,
      },
    },
  },
})

vim.lsp.enable('gopls')

-- BufWritePre for Go: organise imports first, then format (runs once)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    -- 1. Organise imports via codeAction
    local params = vim.lsp.util.make_range_params()   -- fixed: was make_given_range_params
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
    -- 2. Format (gofumpt via gopls)
    vim.lsp.buf.format({ async = false })
  end,
})

-- ─── Python (basedpyright) ───────────────────────────────────────────────────
--
-- Requires: basedpyright  (pip install basedpyright  OR  npm i -g basedpyright)

vim.lsp.config('basedpyright', {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml', 'setup.py', 'setup.cfg',
    'requirements.txt', '.git',
  },
  capabilities = capabilities,
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode       = 'standard',  -- off | basic | standard | strict | all
        autoSearchPaths        = true,
        useLibraryCodeForTypes = true,
        autoImportCompletions  = true,
        diagnosticMode         = 'workspace', -- 'openFilesOnly' | 'workspace'
        inlayHints = {
          variableTypes       = true,
          functionReturnTypes = true,
          callArgumentNames   = true,
          genericTypes        = false,
        },
      },
    },
  },
})

vim.lsp.enable('basedpyright')

-- Format on save: use ruff if available, otherwise fall back to LSP format
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    if vim.fn.executable('ruff') == 1 then
      vim.lsp.buf.format({
        async  = false,
        filter = function(client) return client.name == 'ruff' end,
      })
    else
      vim.lsp.buf.format({ async = false })
    end
  end,
})

-- ─── Global LSP keymaps (apply to every language) ────────────────────────────

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("n", "gd",         vim.lsp.buf.definition,      vim.tbl_extend("force", opts, { desc = "Go to definition" }))
    vim.keymap.set("n", "gD",         vim.lsp.buf.declaration,     vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
    vim.keymap.set("n", "gr",         vim.lsp.buf.references,      vim.tbl_extend("force", opts, { desc = "References" }))
    vim.keymap.set("n", "K",          vim.lsp.buf.hover,           vim.tbl_extend("force", opts, { desc = "Hover docs" }))
    vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename,          vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
    vim.keymap.set("n", "<Leader>ca", vim.lsp.buf.code_action,     vim.tbl_extend("force", opts, { desc = "Code action" }))
    vim.keymap.set("n", "<Leader>f",  function() vim.lsp.buf.format({ async = false }) end,
                                                                    vim.tbl_extend("force", opts, { desc = "Format buffer" }))
    -- Toggle inlay hints (0.11+)
    vim.keymap.set("n", "<Leader>ih", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
    end, vim.tbl_extend("force", opts, { desc = "Toggle inlay hints" }))
  end,
})

-- ─── Diagnostics ─────────────────────────────────────────────────────────────

vim.diagnostic.config({
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN]  = '',
      [vim.diagnostic.severity.HINT]  = '',
      [vim.diagnostic.severity.INFO]  = '',
    },
  },
  update_in_insert = true,
  underline        = true,
  severity_sort    = false,
  float = {
    border    = 'rounded',
    source    = 'always',
    header    = '',
    prefix    = '',
    focusable = false,
    style     = 'minimal',
    format    = function(diagnostic)
      return string.format("%s", diagnostic.message)
    end,
  },
})

-- Show diagnostics float on cursor hold
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false, scope = "cursor" })
  end,
})

-- ─── Completion ──────────────────────────────────────────────────────────────

local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>']     = cmp.mapping.select_prev_item(),
    ['<C-n>']     = cmp.mapping.select_next_item(),
    -- Tab: select next item when menu is open, otherwise insert a real tab
    ['<Tab>']     = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
    -- S-Tab: select prev item when menu is open, otherwise fall through
    ['<S-Tab>']   = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-S-f>']   = cmp.mapping.scroll_docs(-4),
    ['<C-f>']     = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.close(),
    ['<CR>']      = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select   = true,
    }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp', keyword_length = 3, max_item_count = 20, duplicates = false },
  }, {
    { name = 'path' },
    { name = 'nvim_lua',  keyword_length = 2 },
    { name = 'buffer',    keyword_length = 2 },
    { name = 'vsnip',     keyword_length = 2 },
    { name = 'calc' },
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
    completion    = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  formatting = {
    fields = {'menu', 'abbr', 'kind'},
    format = function(entry, item)
      local menu_icon = {
        nvim_lsp = 'λ',
        vsnip    = '⋗',
        buffer   = 'Ω',
        path     = '🖫',
      }
      item.menu = menu_icon[entry.source.name]
      return item
    end,
  },
})

-- LSP signature help border is now handled by lsp_signature.nvim
