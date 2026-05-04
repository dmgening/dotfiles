local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.daily"] = nil
  package.loaded["kb.todo"] = nil
  package.loaded["kb.refresh"] = nil
  return tmp
end

describe("kb.daily.path", function()
  it("returns vault/daily/YYYY-MM-DD.md for a given date", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    assert.are.equal(vault .. "/daily/2026-05-03.md", daily.path("2026-05-03"))
  end)

  it("uses today's date when no date is given", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    local today = os.date("%Y-%m-%d")
    assert.are.equal(vault .. "/daily/" .. today .. ".md", daily.path())
  end)
end)

describe("kb.daily.ensure", function()
  it("creates the daily file with frontmatter and heading if missing", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    local p = daily.ensure("2026-05-03")
    assert.are.equal(vault .. "/daily/2026-05-03.md", p)
    assert.are.equal(1, vim.fn.filereadable(p))
    local lines = vim.fn.readfile(p)
    assert.are.same({
      "---",
      "date: 2026-05-03",
      "---",
      "",
      "# 2026-05-03",
      "",
    }, lines)
  end)

  it("creates parent directory if missing", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    daily.ensure("2026-05-03")
    assert.are.equal(1, vim.fn.isdirectory(vault .. "/daily"))
  end)

  it("does not overwrite an existing daily file", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/daily", "p")
    local p = vault .. "/daily/2026-05-03.md"
    vim.fn.writefile({ "EXISTING CONTENT" }, p)
    local daily = require("kb.daily")
    daily.ensure("2026-05-03")
    assert.are.same({ "EXISTING CONTENT" }, vim.fn.readfile(p))
  end)
end)

describe("kb.daily.append_section", function()
  it("appends ## HH:MM section to today's daily and creates the file if missing", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    local p = daily.append_section("a thought", "2026-05-03")
    assert.are.equal(vault .. "/daily/2026-05-03.md", p)
    local lines = vim.fn.readfile(p)
    local found_section_header = false
    local found_content = false
    for _, l in ipairs(lines) do
      if l:match("^## %d%d:%d%d$") then found_section_header = true end
      if l == "a thought" then found_content = true end
    end
    assert.is_true(found_section_header)
    assert.is_true(found_content)
  end)

  it("preserves prior content when appending", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    daily.append_section("first")
    daily.append_section("second")
    local lines = vim.fn.readfile(daily.path())
    local count = 0
    for _, l in ipairs(lines) do
      if l:match("^## %d%d:%d%d$") then count = count + 1 end
    end
    assert.are.equal(2, count)
  end)

  it("calls todo.sync after appending", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    daily.append_section("- [ ] new task from capture")
    local todo_lines = vim.fn.readfile(vault .. "/todo.md")
    assert.is_true(vim.tbl_contains(todo_lines, "- [ ] new task from capture"))
  end)
end)

describe("kb.daily.append_section with open daily buffer", function()
  it("refreshes the open daily buffer after writing", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    -- Pre-create today's daily so we have a buffer to open.
    daily.ensure()
    vim.cmd("edit " .. vim.fn.fnameescape(daily.path()))
    local buf = vim.api.nvim_get_current_buf()
    daily.append_section("a captured thought")
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local joined = table.concat(lines, "\n")
    assert.is_true(joined:find("a captured thought") ~= nil)
  end)
end)

describe("kb.daily.open_today", function()
  it("creates the file (if missing) and opens it", function()
    local vault = fresh_vault()
    local daily = require("kb.daily")
    daily.open_today()
    local today = os.date("%Y-%m-%d")
    local expected_path = vault .. "/daily/" .. today .. ".md"
    local actual_path = vim.api.nvim_buf_get_name(0)
    -- Compare by resolving both paths to canonical form
    assert.are.equal(vim.fn.resolve(expected_path), vim.fn.resolve(actual_path))
    vim.cmd("bwipeout!")
  end)
end)
