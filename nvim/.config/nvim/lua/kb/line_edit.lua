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
  elseif opts.entry == "S" then
    target_col0 = M.COL_MIN_0IDX
  elseif opts.entry == "C" then
    target_col0 = math.max(cur_col0, M.COL_MIN_0IDX)
  else  -- "i" (default)
    target_col0 = math.max(cur_col0, M.COL_MIN_0IDX)
  end
  vim.api.nvim_win_set_cursor(0, { lnum, target_col0 })

  -- For S/C: clear text before entering insert.
  if opts.entry == "S" or opts.entry == "C" then
    vim.bo[bufnr].modifiable = true
    local prefix
    if opts.entry == "S" then
      prefix = line:sub(1, M.COL_MIN_0IDX)  -- "- [X] "
      target_col0 = M.COL_MIN_0IDX
    else  -- "C"
      prefix = line:sub(1, target_col0)
    end
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { prefix })
    -- Re-fetch line text since we just changed it.
    line = current_line_text(bufnr, lnum)
    vim.api.nvim_win_set_cursor(0, { lnum, target_col0 })
  end

  -- Snapshot baseline for line-count guard. MUST be taken after S/C pre-clear
  -- so the guard doesn't fire spuriously on the first keystroke.
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
  -- Use bang form (startinsert!) for entries that position the cursor at/past
  -- EOL: "A" (append at end), "S" (substitute — clears to EOL, cursor at new
  -- EOL), "C" (change to EOL — cursor at new EOL). Use startreplace for "R"
  -- (replace mode). Plain startinsert for all other entries.
  if opts.entry == "R" then
    vim.cmd("startreplace")
  elseif opts.entry == "A" or opts.entry == "S" or opts.entry == "C" then
    vim.cmd("startinsert!")
  else
    vim.cmd("startinsert")
  end
end

-- Enter visual mode bounded to the current line and to col >= COL_MIN_0IDX.
-- Sets up CursorMoved (line-clamp), TextChanged (line-count guard), and
-- ModeChanged *:n (exit/relock) autocmds. Tears down on ModeChanged.
function M.enter_visual(bufnr)
  bufnr = bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = current_line_text(bufnr, lnum)
  if not M.is_task_line(line) then return end

  -- Pre-clamp cursor.
  local col0 = vim.api.nvim_win_get_cursor(0)[2]
  if col0 < M.COL_MIN_0IDX then col0 = M.COL_MIN_0IDX end
  if col0 > #line - 1 then col0 = math.max(M.COL_MIN_0IDX, #line - 1) end
  vim.api.nvim_win_set_cursor(0, { lnum, col0 })

  local baseline = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local augroup = vim.api.nvim_create_augroup("kb_line_edit_" .. bufnr, { clear = true })
  vim.b[bufnr].kb_line_edit = { lnum = lnum, baseline = baseline, augroup = augroup }

  -- Clamp cursor to the starting line and to col >= COL_MIN_0IDX.
  vim.api.nvim_create_autocmd("CursorMoved", {
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

  -- Line-count guard: block visual-mode deletes that span multiple lines.
  vim.api.nvim_create_autocmd("TextChanged", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      local state = vim.b[bufnr].kb_line_edit
      if not state then return end
      if vim.api.nvim_buf_line_count(bufnr) ~= #state.baseline then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, state.baseline)
        vim.api.nvim_win_set_cursor(0, { state.lnum, M.COL_MIN_0IDX })
        vim.notify("[kb] line-edit: blocked change that would alter line count", vim.log.levels.WARN)
      end
    end,
  })

  -- Tear down when returning to normal mode from visual (ModeChanged).
  -- Note: 'pattern' cannot be combined with 'buffer' in nvim_create_autocmd,
  -- so we check vim.v.event.new_mode inside the callback instead.
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      if vim.v.event and vim.v.event.new_mode == "n" then
        exit(bufnr)
      end
    end,
  })

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_feedkeys("v", "n", false)
end

-- Replace the single character under the cursor with ch (one-shot, no insert
-- mode). If ch is nil, reads the next keypress interactively (keymap path).
-- No-ops when the cursor is inside the checkbox prefix area.
function M.replace_char(bufnr, ch)
  bufnr = bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  if not ch then
    -- Read next char interactively (when called from a keymap without ch arg)
    local code = vim.fn.getchar()
    if type(code) == "number" then
      ch = vim.fn.nr2char(code)
    else
      return  -- non-char input (e.g., escape)
    end
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = current_line_text(bufnr, lnum)
  if not M.is_task_line(line) then return end
  local col0 = vim.api.nvim_win_get_cursor(0)[2]
  if col0 < M.COL_MIN_0IDX then return end
  if col0 >= #line then return end
  local new = line:sub(1, col0) .. ch .. line:sub(col0 + 2)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new })
  pcall(function() vim.cmd("silent! write") end)
  if vim.b[bufnr].kb_todo_unlocked ~= 1 then
    vim.bo[bufnr].modifiable = false
  end
end

-- Yank the task text (col 7 to EOL) into the unnamed register (one-shot).
function M.yank_text(bufnr)
  bufnr = bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = current_line_text(bufnr, lnum)
  if not M.is_task_line(line) then return end
  local task_text = line:sub(M.COL_MIN_0IDX + 1)
  vim.fn.setreg('"', task_text)
end

-- Delete from cursor col to EOL on a task line (one-shot, no insert mode).
-- If cursor is before the editable region, clamps to COL_MIN_0IDX first.
function M.delete_to_eol(bufnr)
  bufnr = bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = current_line_text(bufnr, lnum)
  if not M.is_task_line(line) then return end
  local col0 = vim.api.nvim_win_get_cursor(0)[2]
  if col0 < M.COL_MIN_0IDX then col0 = M.COL_MIN_0IDX end
  local kept = line:sub(1, col0)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { kept })
  pcall(function() vim.cmd("silent! write") end)
  if vim.b[bufnr].kb_todo_unlocked ~= 1 then
    vim.bo[bufnr].modifiable = false
  end
end

return M
