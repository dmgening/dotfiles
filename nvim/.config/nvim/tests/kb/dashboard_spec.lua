local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.dashboard", "kb.refresh" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

describe("kb.dashboard.due_dates", function()
  it("returns empty set when todo.md is missing", function()
    fresh_vault()
    local d = require("kb.dashboard")
    assert.are.same({}, d.due_dates())
  end)

  it("collects due:YYYY-MM-DD from Active, Waiting, Someday", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", table.concat({
      "# TODO",
      "",
      "## Active",
      "- [ ] write spec due:2026-05-10",
      "- [ ] no date here",
      "",
      "## Waiting",
      "- [ ] respond due:2026-05-12",
      "",
      "## Someday",
      "- [ ] vacation due:2026-08-01",
      "",
      "## Done",
      "- [x] should be ignored due:2026-04-01",
      "",
    }, "\n"))
    local d = require("kb.dashboard")
    local got = d.due_dates()
    table.sort(got)
    assert.are.same({ "2026-05-10", "2026-05-12", "2026-08-01" }, got)
  end)

  it("excludes tasks under ## Done", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", table.concat({
      "# TODO",
      "## Active",
      "## Waiting",
      "## Someday",
      "## Done",
      "- [x] done due:2026-05-10",
    }, "\n"))
    assert.are.same({}, require("kb.dashboard").due_dates())
  end)

  it("dedups multiple tasks with the same date", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", table.concat({
      "## Active",
      "- [ ] one due:2026-05-10",
      "- [ ] two due:2026-05-10",
    }, "\n"))
    assert.are.same({ "2026-05-10" }, require("kb.dashboard").due_dates())
  end)

  it("reads from open buffer if todo.md is loaded", function()
    local vault = fresh_vault()
    local todo = vault .. "/todo.md"
    write(todo, "## Active\n- [ ] from disk due:2026-05-10\n")
    vim.cmd("edit " .. vim.fn.fnameescape(todo))
    -- Modify in buffer without saving.
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "## Active", "- [ ] from buffer due:2026-06-01" })
    local got = require("kb.dashboard").due_dates()
    assert.are.same({ "2026-06-01" }, got)
  end)
end)
