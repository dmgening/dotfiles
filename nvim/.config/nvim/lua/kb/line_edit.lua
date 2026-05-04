local M = {}

-- Editable region begins after the 6-char checkbox prefix "- [X] ".
-- Columns are 1-indexed in this comment; nvim_win_get/set_cursor uses 0-indexed columns.
local CHECKBOX_PREFIX_LEN = 6
M.COL_MIN_1IDX = CHECKBOX_PREFIX_LEN + 1  -- 7
M.COL_MIN_0IDX = CHECKBOX_PREFIX_LEN      -- 6

function M.is_task_line(line)
  if not line then return false end
  return line:match("^%- %[.%] ") ~= nil
end

local function current_line_text(bufnr, lnum)
  return vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
end

-- Set cursor (0-indexed col), clamping to the bounds of the editable region on
-- the given line. lnum is 1-indexed.
local function clamp_cursor(bufnr, lnum, col0)
  local line = current_line_text(bufnr, lnum)
  local last_col0 = #line  -- one past last char; nvim allows this in insert mode
  if col0 < M.COL_MIN_0IDX then col0 = M.COL_MIN_0IDX end
  if col0 > last_col0 then col0 = last_col0 end
  vim.api.nvim_win_set_cursor(0, { lnum, col0 })
end

local function exit(bufnr)
  local state = vim.b[bufnr].kb_line_edit
  if not state then return end
  pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
  vim.b[bufnr].kb_line_edit = nil
  if vim.b[bufnr].kb_todo_unlocked == 1 then return end
  pcall(function() vim.cmd("silent! write") end)
  vim.bo[bufnr].modifiable = false
end

-- Enter insert mode bounded to the current line and to col >= COL_MIN_1IDX.
-- opts.entry is currently always "i" in this task; later tasks add other entry
-- variants.
function M.enter_insert(bufnr, opts)
  bufnr = bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  opts = opts or { entry = "i" }
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = current_line_text(bufnr, lnum)
  if not M.is_task_line(line) then return end

  -- Pre-position cursor based on entry variant.
  local cur_col0 = vim.api.nvim_win_get_cursor(0)[2]
  local target_col0
  if opts.entry == "A" then
    -- Position on last char (0-indexed). startinsert moves one past in insert
    -- mode; nvim_win_set_cursor clamps to #line-1 while still in normal mode.
    target_col0 = math.max(#line - 1, M.COL_MIN_0IDX)
  elseif opts.entry == "I" then
    target_col0 = M.COL_MIN_0IDX
  elseif opts.entry == "a" then
    target_col0 = math.max(cur_col0, M.COL_MIN_0IDX) + 1
    if target_col0 > #line then target_col0 = #line end
  else  -- "i" (default)
    target_col0 = math.max(cur_col0, M.COL_MIN_0IDX)
  end
  vim.api.nvim_win_set_cursor(0, { lnum, target_col0 })

  -- Snapshot baseline for line-count guard (later tasks add the guard logic;
  -- for now we just store the snapshot so subsequent tasks don't have to
  -- migrate state shape).
  local baseline = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local augroup = vim.api.nvim_create_augroup("kb_line_edit_" .. bufnr, { clear = true })
  vim.b[bufnr].kb_line_edit = {
    lnum = lnum,
    baseline = baseline,
    augroup = augroup,
  }

  -- Cursor clamp during insert: snap back if user scrolls or arrow-keys to
  -- another line / before col 7.
  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      local state = vim.b[bufnr].kb_line_edit
      if not state then return end
      local pos = vim.api.nvim_win_get_cursor(0)
      if pos[1] ~= state.lnum or pos[2] < M.COL_MIN_0IDX then
        clamp_cursor(bufnr, state.lnum, math.max(pos[2], M.COL_MIN_0IDX))
      end
    end,
  })

  -- Line-count guard: if any edit (paste, <CR>, etc.) would change the number of
  -- lines in the buffer, restore the baseline snapshot and warn.
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    group = augroup,
    buffer = bufnr,
    callback = function()
      local state = vim.b[bufnr].kb_line_edit
      if not state then return end
      local current_count = vim.api.nvim_buf_line_count(bufnr)
      if current_count ~= #state.baseline then
        -- Restore baseline; notify; keep cursor on the original line
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, state.baseline)
        vim.api.nvim_win_set_cursor(0, { state.lnum, M.COL_MIN_0IDX })
        vim.notify("[kb] line-edit: blocked change that would alter line count", vim.log.levels.WARN)
      end
    end,
  })

  -- Tear down on InsertLeave.
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = augroup,
    buffer = bufnr,
    once = true,
    callback = function() exit(bufnr) end,
  })

  vim.bo[bufnr].modifiable = true
  vim.cmd("startinsert")
end

return M
