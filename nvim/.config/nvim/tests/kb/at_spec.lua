local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.at"] = nil
  return tmp
end

describe("kb.at.parse", function()
  it("parses bucketed mention like @reports/vanya", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("hi @reports/vanya there", 4)
    assert.are.same({ bucket = "reports", name = "vanya", raw = "@reports/vanya" }, m)
  end)

  it("parses bare @vanya as bucketless", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("hi @vanya there", 4)
    assert.are.same({ bucket = nil, name = "vanya", raw = "@vanya" }, m)
  end)

  it("returns nil if cursor is not on a mention", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.parse("no mention here", 1))
  end)

  it("parses mention regardless of cursor position within the mention span", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("hi @projects/payments now", 10)
    assert.are.same({ bucket = "projects", name = "payments", raw = "@projects/payments" }, m)
  end)
end)

describe("kb.at.resolve", function()
  it("resolves a flat-form entity file", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/projects", "p")
    vim.fn.writefile({ "# Payments" }, vault .. "/projects/payments.md")
    local at = require("kb.at")
    local p = at.resolve({ bucket = "projects", name = "payments" })
    assert.are.equal(vault .. "/projects/payments.md", p)
  end)

  it("resolves a folder-form entity via index.md", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/domains/labeling", "p")
    vim.fn.writefile({ "# Labeling" }, vault .. "/domains/labeling/index.md")
    local at = require("kb.at")
    local p = at.resolve({ bucket = "domains", name = "labeling" })
    assert.are.equal(vault .. "/domains/labeling/index.md", p)
  end)

  it("prefers flat form when both exist", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/domains/labeling", "p")
    vim.fn.writefile({ "FLAT" }, vault .. "/domains/labeling.md")
    vim.fn.writefile({ "FOLDER" }, vault .. "/domains/labeling/index.md")
    local at = require("kb.at")
    local p = at.resolve({ bucket = "domains", name = "labeling" })
    assert.are.equal(vault .. "/domains/labeling.md", p)
  end)

  it("returns nil if neither flat nor folder form exists", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.resolve({ bucket = "projects", name = "missing" }))
  end)

  it("maps people sub-buckets to people/<bucket>/<name>.md", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/people/reports", "p")
    vim.fn.writefile({ "# Vanya" }, vault .. "/people/reports/vanya.md")
    local at = require("kb.at")
    local p = at.resolve({ bucket = "reports", name = "vanya" })
    assert.are.equal(vault .. "/people/reports/vanya.md", p)
  end)
end)

describe("kb.at.jump", function()
  it("opens the resolved file when cursor is on a valid mention", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/projects", "p")
    vim.fn.writefile({ "# Payments" }, vault .. "/projects/payments.md")
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @projects/payments here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local at = require("kb.at")
    at.jump()
    assert.are.equal(vim.fn.resolve(vault .. "/projects/payments.md"), vim.fn.resolve(vim.api.nvim_buf_get_name(0)))
    vim.cmd("bwipeout!")
  end)

  it("notifies error when cursor is on a bare mention", function()
    fresh_vault()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @vanya here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local notified = nil
    local original_notify = vim.notify
    vim.notify = function(msg, _) notified = msg end
    local at = require("kb.at")
    at.jump()
    vim.notify = original_notify
    assert.is_not_nil(notified)
    assert.is_true(notified:match("specify bucket") ~= nil)
    vim.cmd("bwipeout!")
  end)

  it("notifies error when resolved file does not exist", function()
    fresh_vault()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @projects/missing here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local notified = nil
    local original_notify = vim.notify
    vim.notify = function(msg, _) notified = msg end
    local at = require("kb.at")
    at.jump()
    vim.notify = original_notify
    assert.is_not_nil(notified)
    assert.is_true(notified:match("not found") ~= nil)
    vim.cmd("bwipeout!")
  end)
end)

local function stub_fzf_grep()
  local calls = { grep = {} }
  package.loaded["fzf-lua"] = {
    grep = function(opts) table.insert(calls.grep, opts) end,
  }
  return calls
end

describe("kb.at.backlinks", function()
  it("calls fzf-lua.grep with the mention regex when cursor is on a bucketed mention", function()
    local vault = fresh_vault()
    local calls = stub_fzf_grep()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @reports/vanya here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local at = require("kb.at")
    at.backlinks()
    assert.are.equal(1, #calls.grep)
    assert.are.equal(vault, calls.grep[1].cwd)
    assert.are.equal("@reports/vanya", calls.grep[1].search)
    vim.cmd("bwipeout!")
  end)
end)
