local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.index" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

local function find_by_canonical(entries, canonical)
  for _, e in ipairs(entries) do
    if e.canonical == canonical then return e end
  end
  return nil
end

describe("kb.index.entities", function()
  it("returns empty list for empty vault", function()
    fresh_vault()
    local index = require("kb.index")
    assert.are.same({}, index.entities())
  end)

  it("indexes a flat entity file as kind='entity'", function()
    local vault = fresh_vault()
    write(vault .. "/people/peers/lena.md", "")
    local index = require("kb.index")
    local e = find_by_canonical(index.entities(), "@people/peers/lena")
    assert.is_not_nil(e)
    assert.are.equal("entity", e.kind)
    assert.are.equal(vault .. "/people/peers/lena.md", e.abs_path)
  end)

  it("indexes a folder-form entity (index.md) as kind='entity'", function()
    local vault = fresh_vault()
    write(vault .. "/domains/labeling/index.md", "")
    local index = require("kb.index")
    local e = find_by_canonical(index.entities(), "@domains/labeling")
    assert.is_not_nil(e)
    assert.are.equal("entity", e.kind)
    assert.are.equal(vault .. "/domains/labeling/index.md", e.abs_path)
  end)

  it("indexes non-index sub-files as kind='subfile'", function()
    local vault = fresh_vault()
    write(vault .. "/domains/labeling/index.md", "")
    write(vault .. "/domains/labeling/queries.md", "")
    local index = require("kb.index")
    local sub = nil
    for _, x in ipairs(index.entities()) do
      if x.abs_path == vault .. "/domains/labeling/queries.md" then sub = x end
    end
    assert.is_not_nil(sub)
    assert.are.equal("subfile", sub.kind)
    assert.are.equal("@domains/labeling", sub.parent_canonical)
  end)

  it("ignores top-level files (e.g. todo.md)", function()
    local vault = fresh_vault()
    write(vault .. "/todo.md", "")
    local index = require("kb.index")
    assert.are.same({}, index.entities())
  end)

  it("ignores hidden directories", function()
    local vault = fresh_vault()
    write(vault .. "/.git/people/junk.md", "")
    write(vault .. "/.trash/x.md", "")
    write(vault .. "/.templates/entity.md", "# {{title}}")
    local index = require("kb.index")
    assert.are.same({}, index.entities())
  end)

  it("walks people/, projects/, domains/ recursively", function()
    local vault = fresh_vault()
    write(vault .. "/projects/payments.md", "")
    write(vault .. "/people/leadership/sergey.md", "")
    write(vault .. "/domains/pricing.md", "")
    local index = require("kb.index")
    local entries = index.entities()
    assert.is_not_nil(find_by_canonical(entries, "@projects/payments"))
    assert.is_not_nil(find_by_canonical(entries, "@people/leadership/sergey"))
    assert.is_not_nil(find_by_canonical(entries, "@domains/pricing"))
  end)
end)

describe("kb.index frontmatter", function()
  local function find_by_canonical2(entries, canonical)
    for _, e in ipairs(entries) do
      if e.canonical == canonical then return e end
    end
    return nil
  end

  it("parses aliases (block list)", function()
    local vault = fresh_vault()
    write(vault .. "/people/peers/lena.md", table.concat({
      "---",
      "aliases:",
      "  - lena",
      "  - lp",
      "---",
      "",
      "# Lena",
    }, "\n"))
    local index = require("kb.index")
    local e = find_by_canonical2(index.entities(), "@people/peers/lena")
    assert.are.same({ "lena", "lp" }, e.aliases)
  end)

  it("parses aliases (inline list)", function()
    local vault = fresh_vault()
    write(vault .. "/people/peers/yan.md", table.concat({
      "---",
      "aliases: [yan, yann]",
      "---",
    }, "\n"))
    local index = require("kb.index")
    local e = find_by_canonical2(index.entities(), "@people/peers/yan")
    assert.are.same({ "yan", "yann" }, e.aliases)
  end)

  it("parses title", function()
    local vault = fresh_vault()
    write(vault .. "/projects/payments.md", table.concat({
      "---",
      "title: Payments Pipeline",
      "---",
    }, "\n"))
    local index = require("kb.index")
    local e = find_by_canonical2(index.entities(), "@projects/payments")
    assert.are.equal("Payments Pipeline", e.title)
  end)

  it("handles missing frontmatter (no error, empty aliases, nil title)", function()
    local vault = fresh_vault()
    write(vault .. "/projects/anon.md", "no frontmatter here\n")
    local index = require("kb.index")
    local e = find_by_canonical2(index.entities(), "@projects/anon")
    assert.are.same({}, e.aliases)
    assert.is_nil(e.title)
  end)

  it("survives malformed frontmatter (unclosed)", function()
    local vault = fresh_vault()
    write(vault .. "/projects/broken.md", table.concat({
      "---",
      "title: bad",
      "no closing",
      "",
      "# Body",
    }, "\n"))
    local index = require("kb.index")
    local e = find_by_canonical2(index.entities(), "@projects/broken")
    -- We tolerate it: entity is still indexed, frontmatter fields default.
    assert.is_not_nil(e)
    assert.are.same({}, e.aliases)
  end)
end)

describe("kb.index.tags", function()
  it("scrapes tags from vault content", function()
    local vault = fresh_vault()
    write(vault .. "/projects/x.md", "see #urgent and #q2 today")
    write(vault .. "/people/peers/lena.md", "follow up #followup/manager")
    local index = require("kb.index")
    local tags = index.tags()
    table.sort(tags)
    assert.are.same({ "#followup/manager", "#q2", "#urgent" }, tags)
  end)

  it("returns empty list for empty vault", function()
    fresh_vault()
    local index = require("kb.index")
    assert.are.same({}, index.tags())
  end)

  it("dedupes tags across files", function()
    local vault = fresh_vault()
    write(vault .. "/projects/a.md", "#blocked here")
    write(vault .. "/projects/b.md", "still #blocked")
    local index = require("kb.index")
    assert.are.same({ "#blocked" }, index.tags())
  end)

  it("does not match # in code-like contexts where preceded by alphanumeric", function()
    local vault = fresh_vault()
    write(vault .. "/projects/code.md", "abc#notatag #realtag")
    local index = require("kb.index")
    assert.are.same({ "#realtag" }, index.tags())
  end)
end)

describe("kb.index.refresh", function()
  it("rebuilds entities cache after vault changes", function()
    local vault = fresh_vault()
    write(vault .. "/projects/a.md", "")
    local index = require("kb.index")
    assert.are.equal(1, #index.entities())
    write(vault .. "/projects/b.md", "")
    -- Without refresh, cache is stale
    assert.are.equal(1, #index.entities())
    index.refresh()
    assert.are.equal(2, #index.entities())
  end)
end)

describe("kb.index.refresh_file", function()
  local function find_by_canonical3(entries, canonical)
    for _, e in ipairs(entries) do
      if e.canonical == canonical then return e end
    end
    return nil
  end

  it("updates an existing entry's frontmatter", function()
    local vault = fresh_vault()
    local p = vault .. "/projects/x.md"
    write(p, "---\ntitle: Old\n---\n")
    local index = require("kb.index")
    assert.are.equal("Old", find_by_canonical3(index.entities(), "@projects/x").title)
    write(p, "---\ntitle: New\n---\n")
    index.refresh_file(p)
    assert.are.equal("New", find_by_canonical3(index.entities(), "@projects/x").title)
  end)

  it("inserts a new entry when a new file is saved", function()
    local vault = fresh_vault()
    local index = require("kb.index")
    assert.are.equal(0, #index.entities())
    local p = vault .. "/projects/new.md"
    write(p, "")
    index.refresh_file(p)
    assert.is_not_nil(find_by_canonical3(index.entities(), "@projects/new"))
  end)

  it("merges new tags from the saved file into the global set", function()
    local vault = fresh_vault()
    local p = vault .. "/projects/x.md"
    write(p, "no tags yet")
    local index = require("kb.index")
    assert.are.same({}, index.tags())
    write(p, "now we have #fresh")
    index.refresh_file(p)
    assert.are.same({ "#fresh" }, index.tags())
  end)

  it("drops a tag when no file references it after save", function()
    local vault = fresh_vault()
    local p = vault .. "/projects/x.md"
    write(p, "#disappearing")
    local index = require("kb.index")
    assert.are.same({ "#disappearing" }, index.tags())
    write(p, "gone")
    index.refresh_file(p)
    assert.are.same({}, index.tags())
  end)

  it("ignores files outside the vault", function()
    fresh_vault()
    local index = require("kb.index")
    -- Should not error, should not change state.
    index.refresh_file("/tmp/random/elsewhere.md")
    assert.are.same({}, index.entities())
  end)
end)
