local function reset()
  for _, mod in ipairs({ "kb.config", "kb.refresh" }) do
    package.loaded[mod] = nil
  end
end

local function tmpfile(content)
  local p = vim.fn.tempname() .. ".md"
  vim.fn.writefile(vim.split(content, "\n"), p)
  return p
end

describe("kb.refresh.path", function()
  it("reloads an open buffer when the file on disk changes", function()
    reset()
    local p = tmpfile("one\ntwo\n")
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    local buf = vim.api.nvim_get_current_buf()
    -- Mutate on disk behind nvim's back
    vim.fn.writefile({ "one", "two", "three" }, p)
    require("kb.refresh").path(p)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ "one", "two", "three" }, lines)
  end)

  it("preserves cursor position across reload", function()
    reset()
    local p = tmpfile("a\nb\nc\nd\n")
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    vim.fn.writefile({ "a", "b", "c", "d", "e" }, p)
    require("kb.refresh").path(p)
    local pos = vim.api.nvim_win_get_cursor(0)
    assert.are.equal(3, pos[1])
  end)

  it("skips and notifies when buffer has unsaved edits", function()
    reset()
    local p = tmpfile("clean\n")
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "dirty" })
    -- Buffer is now modified
    vim.fn.writefile({ "from-disk" }, p)
    local notified = false
    local orig_notify = vim.notify
    vim.notify = function(msg, _) if msg:match("unsaved edits") then notified = true end end
    require("kb.refresh").path(p)
    vim.notify = orig_notify
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({ "dirty" }, lines)
    assert.is_true(notified)
  end)

  it("is a no-op for paths with no loaded buffer", function()
    reset()
    local p = tmpfile("hello\n")
    -- Don't open it. Just call refresh.path; should not error.
    assert.has_no.errors(function() require("kb.refresh").path(p) end)
  end)
end)

describe("kb.refresh.write_through", function()
  it("writes to disk when no buffer is open for the path", function()
    reset()
    local p = vim.fn.tempname() .. ".md"
    vim.fn.writefile({ "old" }, p)
    require("kb.refresh").write_through(p, function(lines)
      table.insert(lines, "new")
      return lines
    end)
    assert.are.same({ "old", "new" }, vim.fn.readfile(p))
  end)

  it("writes through buffer when open (modifies, marks dirty, no disk write)", function()
    reset()
    local p = vim.fn.tempname() .. ".md"
    vim.fn.writefile({ "old" }, p)
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    require("kb.refresh").write_through(p, function(lines)
      table.insert(lines, "new")
      return lines
    end)
    -- Buffer should reflect the new content.
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert.are.same({ "old", "new" }, lines)
    -- Buffer should be modified (user must :w to persist).
    assert.is_true(vim.bo[0].modified)
    -- Disk should still have the old content.
    assert.are.same({ "old" }, vim.fn.readfile(p))
  end)

  it("creates the file if it didn't exist (no-buffer path)", function()
    reset()
    local p = vim.fn.tempname() .. ".md"
    require("kb.refresh").write_through(p, function(lines)
      assert.are.same({}, lines)
      return { "fresh" }
    end)
    assert.are.same({ "fresh" }, vim.fn.readfile(p))
  end)
end)

describe("kb.refresh non-modifiable buffer", function()
  it("refresh.path succeeds when target buffer is non-modifiable", function()
    reset()
    local p = tmpfile("one\ntwo\n")
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].modifiable = false
    -- Mutate on disk behind nvim's back
    vim.fn.writefile({ "one", "two", "three" }, p)
    -- Should not error even though buffer is non-modifiable
    assert.has_no.errors(function() require("kb.refresh").path(p) end)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ "one", "two", "three" }, lines)
    -- Buffer should still be non-modifiable after refresh (lock preserved)
    assert.is_false(vim.bo[buf].modifiable, "expected modifiable=false to be restored")
  end)

  it("write_through succeeds when target buffer is non-modifiable", function()
    reset()
    local p = vim.fn.tempname() .. ".md"
    vim.fn.writefile({ "old" }, p)
    vim.cmd("edit " .. vim.fn.fnameescape(p))
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].modifiable = false
    assert.has_no.errors(function()
      require("kb.refresh").write_through(p, function(lines)
        table.insert(lines, "new")
        return lines
      end)
    end)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.are.same({ "old", "new" }, lines)
    assert.is_false(vim.bo[buf].modifiable, "expected modifiable=false to be restored")
  end)
end)

describe("kb.refresh.todo", function()
  it("delegates to refresh.path with the vault todo path", function()
    reset()
    _G.KB_VAULT_OVERRIDE = "/tmp/kb-refresh-todo-test"
    package.loaded["kb.config"] = nil
    local refresh = require("kb.refresh")
    local got
    local orig_path = refresh.path
    refresh.path = function(p) got = p end
    refresh.todo()
    refresh.path = orig_path
    assert.are.equal("/tmp/kb-refresh-todo-test/todo.md", got)
    _G.KB_VAULT_OVERRIDE = nil
  end)
end)
