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
