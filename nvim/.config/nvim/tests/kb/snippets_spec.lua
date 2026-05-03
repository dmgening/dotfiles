local function reset()
  for _, mod in ipairs({ "kb.snippets" }) do
    package.loaded[mod] = nil
  end
end

describe("kb.snippets", function()
  it("returns a table indexed by trigger", function()
    reset()
    local snippets = require("kb.snippets")
    local all = snippets.all()
    assert.is_table(all)
    -- LuaSnip's snippet objects expose .trigger
    local triggers = {}
    for _, s in ipairs(all) do
      triggers[s.trigger] = true
    end
    assert.is_true(triggers["t"])
    assert.is_true(triggers["due"])
    assert.is_true(triggers["prio"])
  end)

  it("'t' snippet expands to '- [ ] '", function()
    reset()
    local snippets = require("kb.snippets")
    local s = nil
    for _, x in ipairs(snippets.all()) do
      if x.trigger == "t" then s = x end
    end
    assert.is_not_nil(s)
    -- LuaSnip stores the literal nodes in s.nodes
    -- Body shape: t("- [ ] ")
    local first = s.nodes[1]
    assert.are.same({ "- [ ] " }, first:get_static_text())
  end)

  it("'due' snippet pre-fills today in YYYY-MM-DD", function()
    reset()
    local snippets = require("kb.snippets")
    local s = nil
    for _, x in ipairs(snippets.all()) do
      if x.trigger == "due" then s = x end
    end
    assert.is_not_nil(s)
    -- Body shape: t("due:") + i(1, today)
    local prefix = s.nodes[1]:get_static_text()
    assert.are.same({ "due:" }, prefix)
    local today = os.date("%Y-%m-%d")
    local placeholder = s.nodes[2]:get_static_text()
    assert.are.same({ today }, placeholder)
  end)

  it("'prio' snippet has a choice node with low/mid/high", function()
    reset()
    local snippets = require("kb.snippets")
    local s = nil
    for _, x in ipairs(snippets.all()) do
      if x.trigger == "prio" then s = x end
    end
    assert.is_not_nil(s)
    -- Body shape: t("prio:") + c(1, { t"low", t"mid", t"high" })
    local prefix = s.nodes[1]:get_static_text()
    assert.are.same({ "prio:" }, prefix)
    local choice = s.nodes[2]
    -- choice nodes expose their alternatives via .choices
    assert.are.equal(3, #choice.choices)
    assert.are.same({ "low" }, choice.choices[1]:get_static_text())
    assert.are.same({ "mid" }, choice.choices[2]:get_static_text())
    assert.are.same({ "high" }, choice.choices[3]:get_static_text())
  end)
end)
