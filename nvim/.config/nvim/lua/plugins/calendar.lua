return {
  {
    "mattn/calendar-vim",
    cmd = { "Calendar", "CalendarH", "CalendarT", "CalendarVR" },
    init = function()
      -- calendar-vim defaults are fine; year view is the kb dashboard's preferred layout.
      vim.g.calendar_no_mappings = 0
    end,
  },
}
