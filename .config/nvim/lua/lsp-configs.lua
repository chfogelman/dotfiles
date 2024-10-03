-- Set up language servers.
local lspconfig = require('lspconfig')
local ra_cmds = require('analyzer-commands')

lspconfig.util.on_setup = lspconfig.util.add_hook_before(lspconfig.util.on_setup,
    function(config)
        if config.name == "rust-analyzer" then
            config.capabilities.experimental['localDocs'] = true
        end
    end
)

lspconfig.pyright.setup {}

lspconfig.rust_analyzer.setup {
    -- Server-specific settings. See `:help lspconfig-setup`
    cmd = { 'rust-analyzer', '+nightly' },
    settings = {
        ['rust-analyzer'] = {
            rustfmt = {
                extraArgs = { '+nightly' },
            },
        },
    },
    on_attach = function(_client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'JoinLines', ra_cmds.join_lines, { range = true })
        vim.keymap.set({ 'n', 'v' }, 'J', '<cmd>JoinLines<CR>', { buffer = bufnr })
        vim.api.nvim_create_user_command('FindParentModule', ra_cmds.find_parent_module, {})
        vim.keymap.set('n', '%', ra_cmds.find_matching_brace, { buffer = bufnr })
    end,
}

lspconfig.lua_ls.setup {
    on_init = function(client)
        local path = client.workspace_folders[1].name
        if not vim.loop.fs_stat(path .. '/.luarc.json') and not vim.loop.fs_stat(path .. '/.luarc.jsonc') then
            client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
                Lua = {
                    runtime = {
                        version = 'LuaJIT'
                    },
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME
                            -- "${3rd}/luv/library"
                            -- "${3rd}/busted/library",
                        }
                        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                        -- library = vim.api.nvim_get_runtime_file("", true)
                    }
                }
            })
            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end
        return true
    end
}

lspconfig.clangd.setup {}



-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>eo', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>ep', vim.diagnostic.goto_prev)
vim.keymap.set('n', '<leader>en', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>ee', function()
    vim.diagnostic.setqflist {
        severity = vim.diagnostic.severity.ERROR,
    }
end)
vim.keymap.set('n', '<leader>ea', vim.diagnostic.setqflist)
vim.keymap.set('n', '<leader>eb', vim.diagnostic.setloclist)

local lsp_group = vim.api.nvim_create_augroup('UserLspConfig', {})
-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
    group = lsp_group,
    callback = function(event)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[event.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

--        vim.api.nvim_create_autocmd('BufWritePre', {
--            group = lsp_group,
--            buffer = event.buf,
--            callback = function(ev)
--                vim.lsp.buf.format()
--            end,
--        })
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
        vim.keymap.set('n', '<leader>gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, opts)
        vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, opts)
        vim.keymap.set('n', '<leader>gC', vim.lsp.buf.outgoing_calls, opts)
        vim.keymap.set('n', '<leader>gc', vim.lsp.buf.incoming_calls, opts)
        vim.keymap.set('n', '<leader>gh', "<cmd>ClangdSwitchSourceHeader<CR>", opts)
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
        vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
        vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('i', '<C-n>', '<C-x><C-o>', opts)
        vim.keymap.set('i', '<CR>', function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>" end,
            { buffer = event.buf, expr = true })
    end,
})

vim.api.nvim_create_autocmd('LspTokenUpdate', {
    group = lsp_group,
    callback = function(args)
        vim.lsp.semantic_tokens.highlight_token(
            args.data.token,
            args.buf,
            args.data.client_id,
            'MyMutableVariableHighlight'
        )
    end,
})

vim.api.nvim_set_hl(0, 'LspReferenceText', { link = "CursorLine" })
vim.api.nvim_set_hl(0, 'LspReferenceRead', { link = "CursorLine" })
vim.api.nvim_set_hl(0, 'LspReferenceWrite', { link = "CursorLine" })
