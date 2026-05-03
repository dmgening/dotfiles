local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.at" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

describe("kb.at.backlinks_for_target", function()
  it("finds rooted, relative, and bare-filename backlinks to the same target", function()
    local vault = fresh_vault()
    -- Target file:
    write(vault .. "/domains/labeling/queries.md", "")
    -- Backlinks in three syntactic forms:
    write(vault .. "/projects/payments.md", "See [Q](/domains/labeling/queries.md) for ref.")
    write(vault .. "/domains/pricing.md", "Cf [Q](labeling/queries.md).")
    write(vault .. "/domains/labeling/index.md", "See [Q](queries.md).")
    -- A false-positive same-name target:
    write(vault .. "/projects/other/queries.md", "")
    write(vault .. "/projects/other/index.md", "Local [Q](queries.md).")  -- points to projects/other/queries.md, NOT the target.
    local results = require("kb.at").backlinks_for_target(vault .. "/domains/labeling/queries.md")
    -- results: list of { file, line, text }
    assert.are.equal(3, #results)
    local files = {}
    for _, r in ipairs(results) do files[r.file] = true end
    assert.is_true(files[vault .. "/projects/payments.md"])
    assert.is_true(files[vault .. "/domains/pricing.md"])
    assert.is_true(files[vault .. "/domains/labeling/index.md"])
    assert.is_nil(files[vault .. "/projects/other/index.md"])
  end)

  it("returns empty list when no backlinks exist", function()
    local vault = fresh_vault()
    write(vault .. "/x.md", "")
    local results = require("kb.at").backlinks_for_target(vault .. "/x.md")
    assert.are.same({}, results)
  end)
end)
