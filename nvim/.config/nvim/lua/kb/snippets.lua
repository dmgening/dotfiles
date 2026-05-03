local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

local M = {}

function M.all()
  return {
    s({ trig = "t", desc = "todo item" }, {
      t("- [ ] "),
    }),
    s({ trig = "due", desc = "due-date property (today pre-filled)" }, {
      t("due:"),
      i(1, os.date("%Y-%m-%d")),
    }),
    s({ trig = "prio", desc = "priority property (low/mid/high)" }, {
      t("prio:"),
      c(1, {
        t("low"),
        t("mid"),
        t("high"),
      }),
    }),
  }
end

return M
