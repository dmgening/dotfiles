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

describe("kb.images.on_buf_write_pre", function()
  it("migrates referenced tmps to vault/images and rewrites the link", function()
    local vault = fresh_vault()
    local md = vault .. "/file.md"
    vim.fn.writefile({ "" }, md)
    vim.cmd("edit " .. vim.fn.fnameescape(md))
    local images = require("kb.images")
    -- Set up a pending tmp + buffer line referencing it.
    local tmp = "/tmp/kb-paste-test1.png"
    vim.fn.writefile({ "fake" }, tmp)
    images.pending[vim.api.nvim_get_current_buf()] = { tmp }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "before ![](file://" .. tmp .. ") after" })
    -- Trigger the pre-write hook.
    images.on_buf_write_pre(vim.api.nvim_get_current_buf())
    -- Buffer line should be rewritten to /images/<...>.png form.
    local line = vim.api.nvim_get_current_line()
    assert.is_true(line:match("!%[%]%(/images/[^)]+%.png%)") ~= nil, "got: " .. line)
    -- Tmp should no longer exist; vault image should.
    assert.are.equal(0, vim.fn.filereadable(tmp))
    -- Find the new vault image filename from the buffer line.
    local new_name = line:match("!%[%]%(/images/([^)]+)%)")
    assert.is_not_nil(new_name)
    assert.are.equal(1, vim.fn.filereadable(vault .. "/images/" .. new_name))
    -- Pending registry should be empty for this buffer.
    assert.are.same({}, images.pending_for(vim.api.nvim_get_current_buf()))
  end)

  it("removes tmps that are no longer referenced (deleted from buffer)", function()
    local vault = fresh_vault()
    local md = vault .. "/file.md"
    vim.fn.writefile({ "" }, md)
    vim.cmd("edit " .. vim.fn.fnameescape(md))
    local images = require("kb.images")
    local tmp = "/tmp/kb-paste-test2.png"
    vim.fn.writefile({ "fake" }, tmp)
    images.pending[vim.api.nvim_get_current_buf()] = { tmp }
    -- Buffer does NOT reference the tmp (user deleted the link).
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "no link here" })
    images.on_buf_write_pre(vim.api.nvim_get_current_buf())
    assert.are.equal(0, vim.fn.filereadable(tmp))
    assert.are.same({}, images.pending_for(vim.api.nvim_get_current_buf()))
  end)
end)
