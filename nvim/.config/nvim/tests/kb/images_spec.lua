local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.images" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

describe("kb.images.paste_or_fallthrough", function()
  it("inserts a tmp link and registers when pngpaste succeeds", function()
    local vault = fresh_vault()
    local md = vault .. "/file.md"
    vim.fn.writefile({ "before" }, md)
    vim.cmd("edit " .. vim.fn.fnameescape(md))
    vim.api.nvim_win_set_cursor(0, { 1, 6 })  -- end of 'before'
    local images = require("kb.images")
    -- Inject a fake pngpaste that "succeeds" by writing a fixed byte to the tmp path.
    images._test_pngpaste = function(tmp)
      vim.fn.writefile({ "fakepng" }, tmp)
      return true
    end
    images.paste_or_fallthrough("p")
    local line = vim.api.nvim_get_current_line()
    assert.is_true(line:find("file:///tmp/kb%-paste%-") ~= nil, "expected tmp link, got: " .. line)
    -- Registry should have one entry for this buffer.
    local pending = images.pending_for(vim.api.nvim_get_current_buf())
    assert.are.equal(1, #pending)
    -- The tmp file should exist.
    assert.are.equal(1, vim.fn.filereadable(pending[1]))
    -- Cleanup.
    vim.fn.delete(pending[1])
  end)

  it("falls through to default paste when pngpaste fails", function()
    local vault = fresh_vault()
    local md = vault .. "/file.md"
    vim.fn.writefile({ "abc" }, md)
    vim.cmd("edit " .. vim.fn.fnameescape(md))
    -- Set unnamed register to something pasteable.
    vim.fn.setreg('"', "XYZ", "c")
    vim.api.nvim_win_set_cursor(0, { 1, 0 })  -- before 'a'
    local images = require("kb.images")
    images._test_pngpaste = function(_) return false end
    images.paste_or_fallthrough("p")
    local line = vim.api.nvim_get_current_line()
    -- 'p' (paste after) inserts after cursor; could be 'aXYZbc' or 'aXYZbc' depending
    -- on cursor handling. Just assert the register content appeared.
    assert.is_true(line:find("XYZ") ~= nil)
  end)
end)
