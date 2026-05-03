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

describe("kb.dashboard.open", function()
  before_each(function()
    -- Close any leftover dashboard tabs from prior tests.
    while vim.fn.tabpagenr("$") > 1 do vim.cmd("tabclose") end
  end)

  it("opens a new tab with two windows; left shows todo.md", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", "## Active\n")
    -- Stub :Calendar so the test doesn't depend on calendar-vim.
    vim.api.nvim_create_user_command("Calendar", function() vim.cmd("rightbelow vsplit | enew") end, { nargs = "*" })
    require("kb.dashboard").open()
    assert.are.equal(2, #vim.api.nvim_tabpage_list_wins(0))
    local left_win = vim.api.nvim_tabpage_list_wins(0)[1]
    local left_buf = vim.api.nvim_win_get_buf(left_win)
    local name = vim.api.nvim_buf_get_name(left_buf)
    assert.is_true(name:match("todo%.md$") ~= nil)
    pcall(vim.api.nvim_del_user_command, "Calendar")
  end)
end)

describe("kb.dashboard.toggle_left", function()
  it("swaps the left buffer between todo.md and today's daily", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", "## Active\n")
    -- Stub :Calendar so the test doesn't depend on calendar-vim.
    vim.api.nvim_create_user_command("Calendar", function() vim.cmd("rightbelow vsplit | enew") end, { nargs = "*" })
    require("kb.dashboard").open()
    -- Move to left window
    local left_win = vim.api.nvim_tabpage_list_wins(0)[1]
    vim.api.nvim_set_current_win(left_win)
    require("kb.dashboard").toggle_left()
    local name = vim.api.nvim_buf_get_name(0)
    assert.is_true(name:match("daily/%d%d%d%d%-%d%d%-%d%d%.md$") ~= nil, "expected today's daily, got " .. name)
    require("kb.dashboard").toggle_left()
    name = vim.api.nvim_buf_get_name(0)
    assert.is_true(name:match("todo%.md$") ~= nil, "expected todo.md, got " .. name)
    pcall(vim.api.nvim_del_user_command, "Calendar")
  end)
end)

describe("kb.dashboard.jump_calendar_date", function()
  it("opens an existing daily for the date passed in", function()
    local vault = fresh_vault()
    local daily = vault .. "/daily/2026-04-28.md"
    write(daily, "# 2026-04-28\n")
    -- Set up a left window pointing at todo.md so jump can replace its buffer.
    write(vault .. "/todo.md", "## Active\n")
    vim.cmd("edit " .. vim.fn.fnameescape(vault .. "/todo.md"))
    require("kb.dashboard").jump_calendar_date_for("2026-04-28")
    local name = vim.api.nvim_buf_get_name(0)
    assert.is_true(name:match("daily/2026%-04%-28%.md$") ~= nil, "expected daily; got " .. name)
  end)

  it("notifies and does not change buffer when the daily does not exist", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", "## Active\n")
    vim.cmd("edit " .. vim.fn.fnameescape(vault .. "/todo.md"))
    local notified = false
    local orig = vim.notify
    vim.notify = function(msg, _) if msg:find("no daily") then notified = true end end
    require("kb.dashboard").jump_calendar_date_for("2026-04-28")
    vim.notify = orig
    assert.is_true(notified)
    local name = vim.api.nvim_buf_get_name(0)
    assert.is_true(name:match("todo%.md$") ~= nil, "expected todo.md; got " .. name)
  end)
end)

describe("kb.dashboard.rebuild_marks", function()
  it("sets g:calendar_sign to mark only due dates", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", "## Active\n- [ ] x due:2026-05-10\n")
    require("kb.dashboard").rebuild_marks()
    -- g:calendar_sign should be a function-like object that returns "*" for
    -- (10, 5, 2026) and "" for unrelated dates.
    local fn = vim.g.calendar_sign
    assert.is_not_nil(fn)
    -- calendar-vim invokes g:calendar_sign as a Vim funcref via call().
    local marked = vim.fn.call(fn, { 10, 5, 2026 })
    local unmarked = vim.fn.call(fn, { 11, 5, 2026 })
    assert.are.equal("*", marked)
    assert.are.equal("", unmarked)
  end)
end)
