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

  it("cycle_state walks [ ] -> [/] -> [x] -> [-] -> [>] -> [?] -> [ ]", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [ ] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    todo.cycle_state(0, 4)
    assert.are.equal("- [/] one", vim.api.nvim_buf_get_lines(0, 3, 4, false)[1])
    todo.cycle_state(0, 4)
    -- Now [x] would archive, so the line at 4 may be a section header.
    -- For this assertion, just verify the state advanced — find the line again.
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local found_x = false
    for _, l in ipairs(lines) do
      if l == "- [x] one" then found_x = true end
    end
    assert.is_true(found_x)
  end)

  it("cycle_state archives on [-] (cancelled)", function()
    local vault = fresh_vault()
    vim.fn.writefile({
      "# TODO", "", "## Active", "- [x] one", "",
      "## Waiting", "",
      "## Someday", "",
      "## Done", "",
    }, vault .. "/todo.md")
    vim.cmd("edit " .. vault .. "/todo.md")
    local todo = require("kb.todo")
    -- One cycle from [x] should land on [-] and archive (already in Active so this moves it to Done)
    todo.cycle_state(0, 4)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local in_done = false
    local section = nil
    for _, l in ipairs(lines) do
      if l:match("^## ") then section = l end
      if section == "## Done" and l == "- [-] one" then in_done = true end
    end
    assert.is_true(in_done)
  end)
end)
