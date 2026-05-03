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

return M
