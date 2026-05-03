local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  vim.fn.mkdir(tmp .. "/daily", "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.todo"] = nil
  return tmp
end

local function write_daily(vault, date, lines)
  local p = vault .. "/daily/" .. date .. ".md"
  vim.fn.writefile(lines, p)
  return p
end

describe("kb.todo.path", function()
  it("returns vault/todo.md", function()
    local vault = fresh_vault()
    local todo = require("kb.todo")
    assert.are.equal(vault .. "/todo.md", todo.path())
  end)
end)

describe("kb.todo.sync", function()
  it("creates todo.md with the standard structure if missing", function()
    local vault = fresh_vault()
    local daily_path = write_daily(vault, "2026-05-03", {
      "## 09:42",
      "- [ ] talk to @reports/vanya",
    })
    local todo = require("kb.todo")
    local changed = todo.sync(daily_path)
    assert.is_true(changed)
    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    assert.is_true(vim.tbl_contains(todo_lines, "# TODO"))
    assert.is_true(vim.tbl_contains(todo_lines, "## Active"))
    assert.is_true(vim.tbl_contains(todo_lines, "## Waiting"))
    assert.is_true(vim.tbl_contains(todo_lines, "## Someday"))
    assert.is_true(vim.tbl_contains(todo_lines, "- [ ] talk to @reports/vanya"))
  end)

  it("appends new tasks under ## Active", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO",
      "",
      "## Active",
      "- [ ] existing task",
      "",
      "## Waiting",
      "",
      "## Someday",
      "",
    }, vault .. "/todo.md")
    local daily_path = write_daily(vault, "2026-05-03", {
      "## 09:42",
      "- [ ] new task",
    })
    local todo = require("kb.todo")
    todo.sync(daily_path)
    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    local found_existing, found_new = false, false
    for _, l in ipairs(todo_lines) do
      if l == "- [ ] existing task" then found_existing = true end
      if l == "- [ ] new task" then found_new = true end
    end
    assert.is_true(found_existing)
    assert.is_true(found_new)
  end)

  it("is idempotent — does not duplicate exact-match tasks", function()
    local vault = fresh_vault()
    local daily_path = write_daily(vault, "2026-05-03", {
      "## 09:42",
      "- [ ] dedupe me",
    })
    local todo = require("kb.todo")
    todo.sync(daily_path)
    local first_lines = vim.fn.readfile(vault .. "/todo.md")
    local first_count = 0
    for _, l in ipairs(first_lines) do
      if l == "- [ ] dedupe me" then first_count = first_count + 1 end
    end
    assert.are.equal(1, first_count)

    local changed = todo.sync(daily_path)
    assert.is_false(changed)
    local second_lines = vim.fn.readfile(vault .. "/todo.md")
    local second_count = 0
    for _, l in ipairs(second_lines) do
      if l == "- [ ] dedupe me" then second_count = second_count + 1 end
    end
    assert.are.equal(1, second_count)
  end)

  it("ignores [x] (already-done) lines", function()
    local vault = fresh_vault()
    local daily_path = write_daily(vault, "2026-05-03", {
      "## 09:42",
      "- [x] already done",
      "- [ ] still open",
    })
    local todo = require("kb.todo")
    todo.sync(daily_path)
    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    assert.is_false(vim.tbl_contains(todo_lines, "- [x] already done"))
    assert.is_true(vim.tbl_contains(todo_lines, "- [ ] still open"))
  end)

  it("inserts ## Active section if todo.md exists but lacks it", function()
    local vault = fresh_vault()
    vim.fn.writefile({ "# TODO", "", "## Waiting", "" }, vault .. "/todo.md")
    local daily_path = write_daily(vault, "2026-05-03", {
      "- [ ] new task",
    })
    local todo = require("kb.todo")
    todo.sync(daily_path)
    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    assert.is_true(vim.tbl_contains(todo_lines, "## Active"))
    assert.is_true(vim.tbl_contains(todo_lines, "- [ ] new task"))
  end)
end)

describe("kb.todo helpers", function()
  it("new skeleton includes ## Done", function()
    local vault = fresh_vault()
    local todo = require("kb.todo")
    -- Force creation by syncing an empty daily (no tasks but creates skeleton on miss)
    -- Easier: just call open() then read the file? open() opens nvim. Use sync indirectly.
    -- Direct check: read the SKELETON via a temp open is awkward. Instead, sync from a daily with a task:
    local daily_path = vault .. "/daily/2026-05-03.md"
    vim.fn.mkdir(vault .. "/daily", "p")
    vim.fn.writefile({ "- [ ] task" }, daily_path)
    todo.sync(daily_path)
    local lines = vim.fn.readfile(vault .. "/todo.md")
    local has_done = false
    for _, l in ipairs(lines) do
      if l == "## Done" then has_done = true end
    end
    assert.is_true(has_done)
  end)

  it("move_task moves a task line to the named section bottom", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "- [ ] two", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    -- Open as buffer to satisfy bufnr-based API
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    todo.move_task(0, 4, "Waiting")  -- '- [ ] one' is at line 4 (1-indexed)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- Expect '- [ ] one' under ## Waiting now, removed from Active
    local in_active = false
    local in_waiting = false
    local section = nil
    for _, l in ipairs(lines) do
      if l:match("^## ") then section = l end
      if section == "## Active" and l == "- [ ] one" then in_active = true end
      if section == "## Waiting" and l == "- [ ] one" then in_waiting = true end
    end
    assert.is_false(in_active)
    assert.is_true(in_waiting)
  end)

  it("toggle_state flips [ ] to [x] and archives to ## Done", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    todo.toggle_state(0, 4)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local in_done = false
    local section = nil
    for _, l in ipairs(lines) do
      if l:match("^## ") then section = l end
      if section == "## Done" and l == "- [x] one" then in_done = true end
    end
    assert.is_true(in_done)
  end)

  it("cycle_state walks [ ] -> [/] -> [>] -> [?] -> [ ] (skips archive states)", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    local function state_at(ln) return vim.api.nvim_buf_get_lines(0, ln - 1, ln, false)[1] end
    todo.cycle_state(0, 4); assert.are.equal("- [/] one", state_at(4))
    todo.cycle_state(0, 4); assert.are.equal("- [>] one", state_at(4))
    todo.cycle_state(0, 4); assert.are.equal("- [?] one", state_at(4))
    todo.cycle_state(0, 4); assert.are.equal("- [ ] one", state_at(4))
    -- Task should still be in ## Active throughout (no archiving)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.equal("## Active", lines[3])
    assert.is_truthy(lines[4]:find("one", 1, true))
  end)

  it("cycle_state from [x] in Done un-archives back to ## Active as next non-archive state", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "- [x] one", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    -- File: 1=# TODO 2='' 3=## Active 4='' 5=## Waiting 6='' 7=## Someday
    -- 8='' 9=## Done 10='- [x] one' 11=''
    todo.cycle_state(0, 10)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local section, in_active = nil, false
    for _, l in ipairs(lines) do
      if l:match("^## ") then section = l end
      if section == "## Active" and l == "- [ ] one" then in_active = true end
    end
    assert.is_true(in_active)
  end)

  it("toggle_state cycles [ ] -> [x] -> [-] -> [ ]", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    -- [ ] -> [x], moves to ## Done
    local new_ln = todo.toggle_state(0, 4)
    assert.is_not_nil(new_ln)
    assert.are.equal("- [x] one", vim.api.nvim_buf_get_lines(0, new_ln - 1, new_ln, false)[1])
    -- [x] -> [-], stays in ## Done
    new_ln = todo.toggle_state(0, new_ln)
    assert.are.equal("- [-] one", vim.api.nvim_buf_get_lines(0, new_ln - 1, new_ln, false)[1])
    -- [-] -> [ ], un-archives back to ## Active
    new_ln = todo.toggle_state(0, new_ln)
    assert.are.equal("- [ ] one", vim.api.nvim_buf_get_lines(0, new_ln - 1, new_ln, false)[1])
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local section, in_active = nil, false
    for _, l in ipairs(lines) do
      if l:match("^## ") then section = l end
      if section == "## Active" and l == "- [ ] one" then in_active = true end
    end
    assert.is_true(in_active)
  end)

  it("toggle_state archives on [-] (cancelled) too", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [x] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    -- [x] -> [-], should land in ## Done (already archived but state changes)
    local new_ln = todo.toggle_state(0, 4)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local section, in_done = nil, false
    for _, l in ipairs(lines) do
      if l:match("^## ") then section = l end
      if section == "## Done" and l == "- [-] one" then in_done = true end
    end
    assert.is_true(in_done)
  end)

  it("move_task is a no-op (preserves lnum) when task is already in target section", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "- [ ] two", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local result = todo.move_task(0, 4, "Active")
    assert.are.equal(4, result)
    local after = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same(before, after)
  end)

  it("move_task returns the new lnum so callers can follow the cursor", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    local new_ln = todo.move_task(0, 4, "Done")
    assert.is_not_nil(new_ln)
    assert.are.equal("- [ ] one", vim.api.nvim_buf_get_lines(0, new_ln - 1, new_ln, false)[1])
  end)
end)
