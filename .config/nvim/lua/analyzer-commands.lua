local util = require('lspconfig.util')

local function join_with_preceding(delim, list)
    local string = ""
    for _, s in ipairs(list) do
        string = string .. delim .. s
    end
    return string
end

local function command_from_cargo_runnable(runnable)
    local cmd = runnable.overrideCargo or "cargo"
    cmd = cmd .. join_with_preceding(" ", runnable.cargoArgs) ..
        join_with_preceding(" ", runnable.cargoExtraArgs) .. " --" .. join_with_preceding(" ", runnable.executableArgs)
    return cmd
end

local function _dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. _dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- TODO: have this function reuse buffers
-- Have this function name its buffers
local function view_string(method, params, filetype)
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request(method, params, function(err, result)
        if err then
            error(tostring(err))
        end
        if result then
            local bufnr = vim.api.nvim_create_buf(true, true)
            if filetype then
                vim.bo[bufnr].filetype = filetype
            end
            vim.cmd('rightbelow vertical split')
            vim.api.nvim_win_set_buf(0, bufnr)
            vim.fn.appendbufline(bufnr, 0, vim.fn.split(result.expansion or result, "\n"))
        else
            print("No info for element under cursor")
        end
    end, 0)
end

M = {}

function M.join_lines(args)
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    if client then
        local range = {}
        if not args or args.range == 0 then
            range['start'] = { line = vim.api.nvim_win_get_cursor(0)[1] - 1, character = 0 }
            range['end'] = { line = vim.api.nvim_win_get_cursor(0)[1], character = 0 }
        elseif args.range == 1 then
            range['start'] = { line = args.line1 - 1, character = 0 }
            range['end'] = { line = args.line1, character = 0 }
        else
            range['start'] = { line = args.line1 - 1, character = 0 }
            range['end'] = { line = args.line2 - 1, character = 0 }
        end
        local params = {
            textDocument = { uri = vim.uri_from_bufnr(0) },
            ranges = { range }
        }
        -- client.request('experimental/joinLines', params, function(err, result, ctx)
        --     if err then
        --         error(tostring(err))
        --     end
        --     if result then
        --         vim.lsp.util.apply_text_edits(result, 0, client.offset_encoding)
        --         return
        --     end
        -- end, 0)
    else
        error("This server does not support the JoinLines command")
    end
end

function M.interpret_function()
    -- local split = split_win and type(split_win) == "boolean"
    local pos = vim.lsp.util.make_position_params()
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('rust-analyzer/interpretFunction', pos, function(err, result)
        if err then
            error(tostring(err))
        end
        if result then
            local content = vim.lsp.util.convert_input_to_markdown_lines(result)
            vim.lsp.util.open_floating_preview(content, "text", {})
        end
    end, 0)
end

function M.find_parent_module()
    local params = vim.lsp.util.make_position_params()
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('experimental/parentModule', params, function(err, result)
        if err then
            error(tostring(err))
        end
        if result and result[1] then
            vim.lsp.util.jump_to_location(result[1], client.offset_encoding, true)
        else
            print("No parent module found")
        end
    end, 0)
end

function M.find_matching_brace()
    local doc = vim.lsp.util.make_text_document_params()
    local pos = vim.lsp.util.make_position_params()
    local params = { textDocument = doc, positions = { pos['position'] } }
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('experimental/matchingBrace', params, function(err, result)
        if err then
            error(tostring(err))
        end
        if result then
            pos = result[1]
            vim.api.nvim_win_set_cursor(0, { pos['line'] + 1, pos['character'] })
        end
    end, 0)
end

function M.open_docs(opencmd)
    local params = vim.lsp.util.make_position_params()
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('experimental/externalDocs', params, function(err, result)
        if err then
            error(tostring(err))
        end
        local uri = result['local'] or result.web or result
        if type(uri) == "string" then
            if uri:match('^file') and not util.path.is_file(uri:gsub("^file://", "")) then
                error(uri .. "does not exist")
            end
            vim.cmd("!" .. opencmd .. " " .. uri .. " &")
        else
            print("No documentation to display")
        end
    end, 0)
end

function M.peek_related_tests()
    local params = vim.lsp.util.make_position_params()
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('rust-analyzer/relatedTests', params, function(err, result)
        if err then
            error(tostring(err))
        end
        local locations = {}
        for _, v in ipairs(result) do
            table.insert(locations, v.runnable.location)
        end
        local items = vim.lsp.util.locations_to_items(locations, client.offset_encoding)
        vim.fn.setqflist({}, ' ', { title = "Related Tests", items = items })
        vim.api.nvim_command('botright cwindow')
    end, 0)
end

-- TODO: Reuse buffer for multiple runs
-- Re-run previous test if not on new test
function M.run_test_under_cursor()
    local params = vim.lsp.util.make_position_params()
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('experimental/runnables', params, function(err, result)
        if err then
            error(tostring(err))
        end
        local name = vim.fn.expand('<cword>')
        for _, runnable in ipairs(result) do
            if runnable.label:match(name) then
                local cmd = command_from_cargo_runnable(runnable.args)
                local bufnr = vim.api.nvim_create_buf(false, true)
                vim.cmd('below split')
                vim.api.nvim_win_set_buf(0, bufnr)
                local term = vim.api.nvim_open_term(bufnr, {})
                local job_opts = {
                    cwd = runnable.workspaceRoot,
                    on_stdout = function(_, data, _)
                        for _, d in ipairs(data) do
                            vim.api.nvim_chan_send(term, d .. "\n")
                        end
                    end,
                    pty = true,
                    width = vim.api.nvim_win_get_width(0),
                    height = vim.api.nvim_win_get_height(0),
                }
                vim.fn.jobstart(vim.fn.split(cmd), job_opts)
                return
            end
        end
        print("No runnable found under cursor")
    end, 0)
end

function M.expand_macro()
    view_string('rust-analyzer/expandMacro', vim.lsp.util.make_position_params(), "rust")
end

function M.view_hir()
    view_string("rust-analyzer/viewHir", vim.lsp.util.make_position_params())
end

function M.view_mir()
    view_string("rust-analyzer/viewMir", vim.lsp.util.make_position_params())
end

vim.api.nvim_create_user_command('ViewItemTree', function()
    view_string("rust-analyzer/viewItemTree", { textDocument = vim.lsp.util.make_text_document_params() }, "rust")
end, {})

-- needs parsing :(
function M.view_crate_graph()
    view_string("rust-analyzer/viewCrateGraph", { full = true })
end

function M.open_cargo_toml()
    local doc = vim.lsp.util.make_text_document_params()
    local client = util.get_active_client_by_name(0, "rust_analyzer")
    client.request('experimental/openCargoToml', { textDocument = doc }, function(err, result)
        if err then
            error(tostring(err))
        end
        if result then
            vim.lsp.util.jump_to_location(result, client.offset_encoding, true)
        else
            print("No Cargo.toml found")
        end
    end, 0)
end

function M.analyzer_status(file_only)
    local params = function()
        if file_only then return vim.lsp.util.make_text_document_params() end
    end
    view_string('rust-analyzer/analyzerStatus', params())
end

-- vim.api.nvim_create_user_command('MemoryUsage', function()
--     local client = util.get_active_client_by_name(0, "rust_analyzer")
--     client.request('rust-analyzer/memoryUsage', {}, function(err, result)
--         if err then
--             error(tostring(err))
--         end
--         if result then
--             print(tostring(result))
--         end
--     end, 0)
-- end, {})
return M

-- local anal_commands = require('analyzer-commands')
--
-- vim.api.nvim_create_user_command('JoinLines', anal_commands.join_lines, { range = true })
-- vim.api.nvim_create_user_command('InterpretFunction', anal_commands.interpret_function, {})
-- vim.api.nvim_create_user_command('FindParentModule', anal_commands.find_parent_module, {})
-- vim.api.nvim_create_user_command('FindMatchingBrace', anal_commands.find_matching_brace, {})
-- vim.api.nvim_create_user_command('OpenDocs', function() anal_commands.open_docs("open") end, {})
-- vim.api.nvim_create_user_command('PeekRelatedTests', anal_commands.peek_related_tests, {})
-- vim.api.nvim_create_user_command('Run', anal_commands.run_test_under_cursor, {})
-- vim.api.nvim_create_user_command('ExpandMacro', anal_commands.expand_macro, {})
-- vim.api.nvim_create_user_command('ViewHir', anal_commands.view_hir, {})
-- vim.api.nvim_create_user_command('ViewMir', anal_commands.view_mir, {})
-- vim.api.nvim_create_user_command('OpenCargoToml', anal_commands.open_cargo_toml, {})
-- vim.api.nvim_create_user_command('AnalyzerStatus', function()
--     anal_commands.analyzer_status(true)
-- end, {})
