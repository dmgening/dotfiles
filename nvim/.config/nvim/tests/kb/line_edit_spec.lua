local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.line_edit" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

local function setup_task_buffer(text)
  local vault = fresh_vault()
  local p = vault .. "/todo.md"
  vim.fn.writefile({ "## Active", text }, p)
  vim.cmd("edit " .. vim.fn.fnameescape(p))
  vim.bo.modifiable = false
  vim.api.nvim_win_set_cursor(0, { 2, 7 })  -- on the task line, col 8 (1-indexed; col 7 in 0-indexed = col 8)
  return vim.api.nvim_get_current_buf()
end

describe("kb.line_edit.is_task_line", function()
  it("returns true for '- [ ] foo'", function()
    fresh_vault()
    assert.is_true(require("kb.line_edit").is_task_line("- [ ] foo"))
  end)
  it("returns true for '- [x] done'", function()
    fresh_vault()
    assert.is_true(require("kb.line_edit").is_task_line("- [x] done"))
  end)
  it("returns false for a section header", function()
    fresh_vault()
    assert.is_false(require("kb.line_edit").is_task_line("## Active"))
  end)
  it("returns false for an empty line", function()
    fresh_vault()
    assert.is_false(require("kb.line_edit").is_task_line(""))
  end)
end)

describe("kb.line_edit.enter_insert basic", function()
  it("no-ops when cursor is on a non-task line", function()
    fresh_vault()
    local p = _G.KB_VAULT_OVERRIDE .. "/todo.md"
    vim.fn.writefile({ "## Active", "" }, p)
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    vim.bo.modifiable = false
    vim.api.nvim_win_set_cursor(0, { 1, 0 })  -- on header
    require("kb.line_edit").enter_insert(0, { entry = "i" })
    assert.are.equal("n", vim.fn.mode():sub(1, 1), "expected to stay in normal mode")
    assert.is_false(vim.bo.modifiable, "expected buffer to remain non-modifiable")
  end)

  it("unlocks buffer and sets state when cursor is on a task line", function()
    -- Note: startinsert does not actually enter insert mode in headless nvim (no UI).
    -- We verify the observable side-effects: modifiable=true and kb_line_edit state set.
    local buf = setup_task_buffer("- [ ] hello")
    require("kb.line_edit").enter_insert(0, { entry = "i" })
    assert.is_true(vim.bo[buf].modifiable, "expected buffer to be unlocked")
    assert.is_not_nil(vim.b[buf].kb_line_edit, "expected kb_line_edit state to be set")
    -- Clean up state
    vim.b[buf].kb_line_edit = nil
    vim.bo[buf].modifiable = false
  end)

  it("clamps cursor to col >= 7 on entry when cursor was in checkbox area", function()
    local buf = setup_task_buffer("- [ ] hello")
    vim.api.nvim_win_set_cursor(0, { 2, 1 })  -- col 2 (in checkbox)
    require("kb.line_edit").enter_insert(0, { entry = "i" })
    vim.wait(50)
    local col = vim.api.nvim_win_get_cursor(0)[2]
    assert.is_true(col >= 6, "expected cursor at col >= 7 (1-indexed) i.e. >= 6 (0-indexed); got " .. col)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  end)

  it("relocks buffer on InsertLeave", function()
    setup_task_buffer("- [ ] hello")
    require("kb.line_edit").enter_insert(0, { entry = "i" })
    vim.wait(50)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
    assert.is_false(vim.bo.modifiable, "expected buffer to be relocked after <Esc>")
  end)
end)

describe("kb.line_edit line-count guard", function()
  it("restores buffer if line count changes during a vi-mode session", function()
    local buf = setup_task_buffer("- [ ] foo")
    require("kb.line_edit").enter_insert(buf, { entry = "i" })
    vim.wait(50)

    local before_count = vim.api.nvim_buf_line_count(buf)

    -- Directly inject an extra line to simulate what <CR> or a paste would do.
    -- This triggers the TextChanged autocmd synchronously.
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(lines, 3, "injected extra line")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- Fire TextChanged so the guard can act.
    vim.cmd("doautocmd TextChanged")
    vim.wait(50)

    local after_count = vim.api.nvim_buf_line_count(buf)
    assert.are.equal(before_count, after_count,
      "expected line count unchanged after blocked multi-line change; got " .. after_count)

    -- Clean up: exit insert mode state
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)
end)
