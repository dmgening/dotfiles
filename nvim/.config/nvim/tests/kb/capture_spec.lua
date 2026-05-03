local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.daily"] = nil
  package.loaded["kb.todo"] = nil
  package.loaded["kb.capture"] = nil
  return tmp
end

describe("kb.capture.run", function()
  it("opens a scratch buffer in a floating window", function()
    fresh_vault()
    local capture = require("kb.capture")
    capture.run()
    assert.are.equal("nofile", vim.bo.buftype)
    assert.are.equal("wipe", vim.bo.bufhidden)
    local win_config = vim.api.nvim_win_get_config(0)
    assert.are.equal("editor", win_config.relative)
    vim.cmd("bwipeout!")
  end)

  it("appends buffer content to today's daily on BufUnload", function()
    local vault = fresh_vault()
    local capture = require("kb.capture")
    capture.run()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "captured thought" })
    vim.cmd("bwipeout!")
    local today = os.date("%Y-%m-%d")
    local daily_path = vault .. "/daily/" .. today .. ".md"
    assert.are.equal(1, vim.fn.filereadable(daily_path))
    local lines = vim.fn.readfile(daily_path)
    local found = false
    for _, l in ipairs(lines) do
      if l == "captured thought" then found = true end
    end
    assert.is_true(found)
  end)

  it("does nothing when buffer is empty on close", function()
    local vault = fresh_vault()
    local capture = require("kb.capture")
    capture.run()
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "", "  ", "" })
    vim.cmd("bwipeout!")
    local today = os.date("%Y-%m-%d")
    local daily_path = vault .. "/daily/" .. today .. ".md"
    assert.are.equal(0, vim.fn.filereadable(daily_path))
  end)
end)
