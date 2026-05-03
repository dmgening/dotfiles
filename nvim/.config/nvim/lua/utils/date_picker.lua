local M = {}

-- Returns { date, start_col, end_col } if the cursor (1-indexed column) sits
-- on or inside a YYYY-MM-DD token in the current line. Else nil.
function M.parse_date_token_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1  -- 1-indexed
  local i = 1
  while true do
    local s, e = line:find("%d%d%d%d%-%d%d%-%d%d", i)
    if not s then return nil end
    if col >= s and col <= e then
      return {
        date = line:sub(s, e),
        start_col = s,
        end_col = e,
      }
    end
    i = e + 1
  end
end

-- Apply a YYYY-MM-DD date to the current buffer at cursor:
-- replace token under cursor if present, else insert at cursor.
function M.apply_date(date)
  local token = M.parse_date_token_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if token then
    local new_line = line:sub(1, token.start_col - 1) .. date .. line:sub(token.end_col + 1)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
    vim.api.nvim_win_set_cursor(0, { row, token.start_col - 1 + #date })
  else
    local col = vim.api.nvim_win_get_cursor(0)[2] + 1
    local new_line = line:sub(1, col - 1) .. date .. line:sub(col)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
    vim.api.nvim_win_set_cursor(0, { row, col - 1 + #date })
  end
end

-- Open the calendar popup at the appropriate date and write back on selection.
-- This is the user-facing entry point. Invokes calendar-vim's :CalendarT.
-- The selection callback is registered via g:calendar_action.
function M.pick()
  local token = M.parse_date_token_under_cursor()
  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  -- Stash a one-shot calendar_action that writes back to the source buffer.
  _G._utils_date_picker_callback = function(day, month, year)
    local date = string.format("%04d-%02d-%02d", year, tonumber(month), tonumber(day))
    -- Close the calendar window first.
    vim.cmd("close")
    -- Switch back to the source window/buffer.
    if vim.api.nvim_win_is_valid(source_win) then
      vim.api.nvim_set_current_win(source_win)
    end
    if vim.api.nvim_buf_is_valid(source_buf) then
      vim.api.nvim_set_current_buf(source_buf)
    end
    M.apply_date(date)
    _G._utils_date_picker_callback = nil
  end
  vim.cmd([[
    function! UtilsDatePickerAction(day, month, year, week, dir) abort
      call v:lua._utils_date_picker_callback(a:day, a:month, a:year)
    endfunction
  ]])
  vim.g.calendar_action = "UtilsDatePickerAction"
  if token then
    local y, m, d = token.date:match("(%d%d%d%d)-(%d%d)-(%d%d)")
    vim.cmd(string.format("CalendarT %s %s %s", y, m, d))
  else
    vim.cmd("CalendarT")
  end
end

return M
