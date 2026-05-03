local function reset()
  package.loaded["utils.date_picker"] = nil
end

local function buf_with(text, cursor_col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_cursor(0, { 1, cursor_col - 1 })  -- col is 0-indexed for nvim_win_set_cursor
  return buf
end

describe("utils.date_picker.parse_date_token_under_cursor", function()
  it("returns span when cursor is inside a YYYY-MM-DD token", function()
    reset()
    buf_with("due:2026-05-10 foo", 8)  -- col 8 → '2'
    local got = require("utils.date_picker").parse_date_token_under_cursor()
    assert.is_not_nil(got)
    assert.are.equal("2026-05-10", got.date)
    assert.are.equal(5, got.start_col)
    assert.are.equal(14, got.end_col)
  end)

  it("returns nil when cursor is outside any date token", function()
    reset()
    buf_with("hello world", 3)
    assert.is_nil(require("utils.date_picker").parse_date_token_under_cursor())
  end)

  it("matches a date at line start", function()
    reset()
    buf_with("2026-01-01", 1)
    local got = require("utils.date_picker").parse_date_token_under_cursor()
    assert.is_not_nil(got)
    assert.are.equal("2026-01-01", got.date)
  end)
end)

local function buf_with(text, cursor_col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_cursor(0, { 1, cursor_col - 1 })
  return buf
end

describe("utils.date_picker.apply_date", function()
  it("replaces a date token under cursor", function()
    reset()
    buf_with("due:2026-05-10 foo", 8)
    require("utils.date_picker").apply_date("2027-01-15")
    assert.are.equal("due:2027-01-15 foo", vim.api.nvim_get_current_line())
  end)

  it("inserts at cursor when no date token is under cursor", function()
    reset()
    buf_with("hello |", 7)  -- cursor on the space before bar; will insert after it
    require("utils.date_picker").apply_date("2027-01-15")
    -- "hello |" -> insert at col 7 -> "hello 2027-01-15|"
    -- (Exact behavior: insert before the cursor position, like normal-mode 'P'.
    -- We allow either form; assert the date is present.)
    local line = vim.api.nvim_get_current_line()
    assert.is_true(line:find("2027%-01%-15") ~= nil)
  end)
end)
