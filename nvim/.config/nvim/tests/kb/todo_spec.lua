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
