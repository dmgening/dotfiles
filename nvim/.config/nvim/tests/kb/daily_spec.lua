local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.daily"] = nil
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
