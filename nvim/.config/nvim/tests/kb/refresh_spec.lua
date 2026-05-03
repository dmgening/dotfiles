local function reset()
  for _, mod in ipairs({ "kb.config", "kb.refresh", "kb.dashboard" }) do
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
