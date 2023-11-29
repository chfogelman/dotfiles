-- Setup language servers.
local lspconfig = require('lspconfig')
lspconfig.pyright.setup {}
lspconfig.rust_analyzer.setup {
    -- Server-specific settings. See `:help lspconfig-setup`
    settings = {
        ['rust-analyzer'] = {},
    },
}
lspconfig.lua_ls.setup {}
lspconfig.clangd.setup {}



-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>eo', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>ep', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>en', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>el', vim.diagnostic.setqflist)
vim.keymap.set('n', '<leader>eb', vim.diagnostic.setloclist)

local lsp_group = vim.api.nvim_create_augroup('UserLspConfig', {})
-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = lsp_group,
    callback = function(event)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[event.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        vim.api.nvim_create_autocmd('BufWritePre', {
            group = lsp_group,
            buffer = event.buf,
            callback = function(ev)
                vim.lsp.buf.format()
            end,
        })
        vim.api.nvim_create_autocmd('CursorHold', {
            group = lsp_group,
            buffer = event.buf,
            callback = function(ev)
                vim.lsp.buf.document_highlight()
            end,
        })
        vim.api.nvim_create_autocmd('CursorMoved', {
            group = lsp_group,
            buffer = event.buf,
            callback = function(ev)
                vim.lsp.buf.clear_references()
            end,
        })
        -- Buffer local mappings. See `:help vim.lsp.*` for documentation on any of the below
        -- functions
        local opts = { buffer = event.buf }
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', 'gC', vim.lsp.buf.outgoing_calls, opts)
        vim.keymap.set('n', 'gc', vim.lsp.buf.incoming_calls, opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('i', '<C-n>', '<C-x><C-o>', opts)
    end,
})

vim.api.nvim_set_hl(0, 'LspReferenceText', { link = "CursorLine" })
vim.api.nvim_set_hl(0, 'LspReferenceRead', { link = "CursorLine" })
vim.api.nvim_set_hl(0, 'LspReferenceWrite', { link = "CursorLine" })
