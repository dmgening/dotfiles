local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.index", "kb.cmp" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

describe("kb cmp source", function()
  it("emits entity items with canonical and aliases in filterText", function()
    local vault = fresh_vault()
    write(vault .. "/people/peers/lena.md", "---\naliases:\n  - lena\n  - lp\n---\n")
    local cmp = require("kb.cmp")
    local source = cmp.new_source()
    local items = source:_collect_items("@")  -- test-only helper exposed below
    local lena = nil
    for _, it in ipairs(items) do
      if it.label == "@people/peers/lena" then lena = it end
    end
    assert.is_not_nil(lena)
    -- filterText combines canonical + aliases for fuzzy match
    assert.is_truthy(lena.filterText:find("lena"))
    assert.is_truthy(lena.filterText:find("lp"))
    assert.is_truthy(lena.filterText:find("@people/peers/lena"))
  end)

  it("emits tag items on '#' trigger", function()
    local vault = fresh_vault()
    write(vault .. "/projects/x.md", "see #urgent")
    local cmp = require("kb.cmp")
    local source = cmp.new_source()
    local items = source:_collect_items("#")
    local found = false
    for _, it in ipairs(items) do
      if it.label == "#urgent" then found = true end
    end
    assert.is_true(found)
  end)

  it("entity items have insertText = canonical for kind='entity'", function()
    local vault = fresh_vault()
    write(vault .. "/projects/payments.md", "")
    local cmp = require("kb.cmp")
    local source = cmp.new_source()
    local items = source:_collect_items("@")
    local pay = nil
    for _, it in ipairs(items) do
      if it.label == "@projects/payments" then pay = it end
    end
    assert.is_not_nil(pay)
    assert.are.equal("@projects/payments", pay.insertText)
  end)
end)

describe("kb cmp source — subfile insertion", function()
  it("uses bare filename when target is in same directory", function()
    local vault = fresh_vault()
    write(vault .. "/domains/labeling/index.md", "")
    write(vault .. "/domains/labeling/queries.md", "---\ntitle: BQ Queries\n---\n")
    local cmp = require("kb.cmp")
    local source = cmp.new_source()
    -- Pretend we're editing index.md inside the same folder
    local insert = source:_subfile_insert(
      vault .. "/domains/labeling/queries.md",
      "BQ Queries",
      vault .. "/domains/labeling/index.md"
    )
    assert.are.equal("[BQ Queries](queries.md)", insert)
  end)

  it("uses vault-rooted path when target is elsewhere", function()
    local vault = fresh_vault()
    write(vault .. "/projects/payments.md", "")
    write(vault .. "/domains/labeling/index.md", "")
    write(vault .. "/domains/labeling/queries.md", "")
    local cmp = require("kb.cmp")
    local source = cmp.new_source()
    local insert = source:_subfile_insert(
      vault .. "/domains/labeling/queries.md",
      "Queries",  -- inferred title
      vault .. "/projects/payments.md"
    )
    assert.are.equal("[Queries](/domains/labeling/queries.md)", insert)
  end)

  it("falls back to filename stem when no title", function()
    local vault = fresh_vault()
    write(vault .. "/domains/labeling/index.md", "")
    write(vault .. "/domains/labeling/queries.md", "")
    local cmp = require("kb.cmp")
    local source = cmp.new_source()
    local insert = source:_subfile_insert(
      vault .. "/domains/labeling/queries.md",
      nil,
      vault .. "/domains/labeling/index.md"
    )
    assert.are.equal("[queries](queries.md)", insert)
  end)
end)
