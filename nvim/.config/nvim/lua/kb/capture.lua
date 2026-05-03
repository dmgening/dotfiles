local M = {}

local function open_floating_scratch()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " kb capture ",
    title_pos = "center",
  })

  return buf, win
end

local function buffer_text(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return table.concat(lines, "\n")
end

local function is_blank(text)
  return text:match("^%s*$") ~= nil
end

function M.run()
  local buf, _ = open_floating_scratch()

  vim.api.nvim_create_autocmd("BufUnload", {
    buffer = buf,
    once = true,
    callback = function()
      local text = buffer_text(buf)
      if is_blank(text) then
        return
      end
      require("kb.daily").append_section(text)
    end,
  })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf })

  vim.cmd("startinsert")
end

return M
