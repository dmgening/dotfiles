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

describe("kb.line_edit insert-entry variants", function()
  local function setup()
    local vault = vim.fn.tempname()
    vim.fn.mkdir(vault, "p")
    _G.KB_VAULT_OVERRIDE = vault
    for _, mod in ipairs({ "kb.config", "kb.line_edit" }) do package.loaded[mod] = nil end
    local p = vault .. "/todo.md"
    vim.fn.writefile({ "## Active", "- [ ] hello" }, p)
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    vim.bo.modifiable = false
  end

  it("'A' positions cursor at end of line then enters insert", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 7 })  -- arbitrary mid-task position
    require("kb.line_edit").enter_insert(0, { entry = "A" })
    vim.wait(50)
    -- Note: in headless mode, mode() may not be "i". Verify cursor + state.
    local col = vim.api.nvim_win_get_cursor(0)[2]
    -- "- [ ] hello" has length 11. With startinsert! (bang), cursor jumps
    -- past EOL to col0=11, where vi-natural append happens.
    assert.are.equal(11, col, "expected cursor past EOL (col0=11); got " .. col)
    assert.is_true(vim.bo.modifiable)
    assert.is_not_nil(vim.b.kb_line_edit)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)

  it("'I' jumps cursor to col 7 (first editable) then enters insert", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 9 })  -- mid-task
    require("kb.line_edit").enter_insert(0, { entry = "I" })
    vim.wait(50)
    assert.are.equal(6, vim.api.nvim_win_get_cursor(0)[2], "expected col0=6 (1-indexed col 7)")
    assert.is_true(vim.bo.modifiable)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)

  it("'a' positions cursor one past current col then enters insert", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 6 })  -- col0 6 = first editable
    require("kb.line_edit").enter_insert(0, { entry = "a" })
    vim.wait(50)
    assert.are.equal(7, vim.api.nvim_win_get_cursor(0)[2], "expected cursor moved one right; got " .. vim.api.nvim_win_get_cursor(0)[2])
    assert.is_true(vim.bo.modifiable)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)
end)

describe("kb.line_edit S/C/D operators", function()
  local function setup()
    local vault = vim.fn.tempname()
    vim.fn.mkdir(vault, "p")
    _G.KB_VAULT_OVERRIDE = vault
    for _, mod in ipairs({ "kb.config", "kb.line_edit" }) do package.loaded[mod] = nil end
    local p = vault .. "/todo.md"
    vim.fn.writefile({ "## Active", "- [ ] hello world" }, p)
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    vim.bo.modifiable = false
    return p
  end

  it("'S' clears task text and enters insert at col 7", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 9 })  -- mid-task
    require("kb.line_edit").enter_insert(0, { entry = "S" })
    vim.wait(50)
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
    assert.are.equal("- [ ] ", line, "expected task text cleared; got: " .. tostring(line))
    assert.are.equal(6, vim.api.nvim_win_get_cursor(0)[2])
    assert.is_true(vim.bo.modifiable)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)

  it("'C' clears from cursor to EOL and enters insert", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 11 })  -- col0 11 = on " world"
    require("kb.line_edit").enter_insert(0, { entry = "C" })
    vim.wait(50)
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
    assert.are.equal("- [ ] hello", line)
    assert.are.equal(11, vim.api.nvim_win_get_cursor(0)[2])
    assert.is_true(vim.bo.modifiable)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)

  it("'D' clears from cursor to EOL without entering insert", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 11 })
    require("kb.line_edit").delete_to_eol(0)
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
    assert.are.equal("- [ ] hello", line)
    -- D is one-shot, doesn't enter insert; buffer should be relocked.
    assert.is_false(vim.bo.modifiable, "expected buffer relocked after one-shot delete")
  end)
end)

describe("kb.line_edit R/r/Y", function()
  local function setup()
    local vault = vim.fn.tempname()
    vim.fn.mkdir(vault, "p")
    _G.KB_VAULT_OVERRIDE = vault
    for _, mod in ipairs({ "kb.config", "kb.line_edit" }) do package.loaded[mod] = nil end
    local p = vault .. "/todo.md"
    vim.fn.writefile({ "## Active", "- [ ] hello" }, p)
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    vim.bo.modifiable = false
  end

  it("'r' replaces single char under cursor", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 6 })  -- on 'h'
    require("kb.line_edit").replace_char(0, "X")
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
    assert.are.equal("- [ ] Xello", line)
    assert.is_false(vim.bo.modifiable, "expected buffer relocked")
  end)

  it("'r' on cursor in checkbox area is a no-op", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 2 })  -- in checkbox
    require("kb.line_edit").replace_char(0, "X")
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
    assert.are.equal("- [ ] hello", line, "expected line unchanged")
  end)

  it("'Y' yanks col 7 -> EOL into unnamed register", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 9 })  -- doesn't matter, Y always yanks col 7-EOL
    require("kb.line_edit").yank_text(0)
    assert.are.equal("hello", vim.fn.getreg('"'))
  end)

  it("enter_insert with entry='R' unlocks buffer and sets state", function()
    setup()
    vim.api.nvim_win_set_cursor(0, { 2, 7 })
    require("kb.line_edit").enter_insert(0, { entry = "R" })
    vim.wait(50)
    -- In headless, mode() may not switch to "R". Verify side effects.
    assert.is_true(vim.bo.modifiable)
    assert.is_not_nil(vim.b.kb_line_edit)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
    vim.wait(50)
  end)
end)
