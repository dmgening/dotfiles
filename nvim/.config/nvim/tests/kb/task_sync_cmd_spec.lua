local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  vim.fn.mkdir(tmp .. "/daily", "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.todo", "kb.refresh" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

describe(":KbTaskSync", function()
  before_each(function()
    -- Re-register the command (kb.setup() does this; we replicate the relevant part)
    pcall(vim.api.nvim_del_user_command, "KbTaskSync")
    require("kb").setup()
  end)

  it("syncs tasks from a daily passed as arg into todo.md", function()
    local vault = fresh_vault()
    local daily = vault .. "/daily/2026-05-04.md"
    vim.fn.writefile({ "# 2026-05-04", "", "- [ ] do the thing", "" }, daily)

    vim.cmd("KbTaskSync " .. vim.fn.fnameescape(daily))

    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    local joined = table.concat(todo_lines, "\n")
    assert.is_true(joined:find("%- %[ %] do the thing") ~= nil,
      "expected todo.md to contain the task; got:\n" .. joined)
  end)

  it("syncs from current buffer when no arg given and buffer is a daily", function()
    local vault = fresh_vault()
    local daily = vault .. "/daily/2026-05-05.md"
    vim.fn.writefile({ "# 2026-05-05", "", "- [ ] another thing", "" }, daily)
    vim.cmd("edit " .. vim.fn.fnameescape(daily))

    vim.cmd("KbTaskSync")

    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    local joined = table.concat(todo_lines, "\n")
    assert.is_true(joined:find("%- %[ %] another thing") ~= nil,
      "expected todo.md to contain the task; got:\n" .. joined)
  end)

  it("notifies and is no-op when no arg given and current buffer is not a daily", function()
    fresh_vault()
    -- Open a scratch buffer (not a daily)
    vim.cmd("enew")

    local notified = false
    local orig = vim.notify
    vim.notify = function(msg, _)
      if msg:match("not a daily") then notified = true end
    end
    vim.cmd("KbTaskSync")
    vim.notify = orig

    assert.is_true(notified, "expected notify about non-daily buffer")
  end)
end)
