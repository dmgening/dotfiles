local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  for _, mod in ipairs({ "kb.config", "kb.index", "kb.stub" }) do
    package.loaded[mod] = nil
  end
  return tmp
end

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

describe("kb.stub.template_for", function()
  it("falls back to built-in default when no template exists", function()
    local vault = fresh_vault()
    local stub = require("kb.stub")
    local lines = stub.template_for(vault .. "/people/peers/lena.md")
    assert.are.same({ "# {{title}}", "" }, lines)
  end)

  it("uses root .templates/entity.md when present", function()
    local vault = fresh_vault()
    write(vault .. "/.templates/entity.md", "ROOT TEMPLATE\n# {{title}}\n")
    local stub = require("kb.stub")
    local lines = stub.template_for(vault .. "/people/peers/lena.md")
    assert.are.same({ "ROOT TEMPLATE", "# {{title}}", "" }, lines)
  end)

  it("prefers a more-specific template over root", function()
    local vault = fresh_vault()
    write(vault .. "/.templates/entity.md", "ROOT")
    write(vault .. "/.templates/people/entity.md", "PEOPLE")
    local stub = require("kb.stub")
    local lines = stub.template_for(vault .. "/people/peers/lena.md")
    assert.are.same({ "PEOPLE" }, lines)
  end)

  it("walks up multiple levels to find the most specific match", function()
    local vault = fresh_vault()
    write(vault .. "/.templates/entity.md", "ROOT")
    write(vault .. "/.templates/people/peers/entity.md", "PEERS")
    local stub = require("kb.stub")
    local lines = stub.template_for(vault .. "/people/peers/lena.md")
    assert.are.same({ "PEERS" }, lines)
  end)
end)

describe("kb.stub.substitute", function()
  it("substitutes {{title}}", function()
    local stub = require("kb.stub")
    local out = stub.substitute({ "# {{title}}" }, { title = "Lena" })
    assert.are.same({ "# Lena" }, out)
  end)

  it("substitutes {{date}}", function()
    local stub = require("kb.stub")
    local out = stub.substitute({ "created: {{date}}" }, { date = "2026-05-03" })
    assert.are.same({ "created: 2026-05-03" }, out)
  end)

  it("substitutes {{path}}", function()
    local stub = require("kb.stub")
    local out = stub.substitute({ "ref: {{path}}" }, { path = "@projects/x" })
    assert.are.same({ "ref: @projects/x" }, out)
  end)

  it("handles multiple vars in one line", function()
    local stub = require("kb.stub")
    local out = stub.substitute(
      { "{{title}} created on {{date}}" },
      { title = "X", date = "2026-05-03" }
    )
    assert.are.same({ "X created on 2026-05-03" }, out)
  end)

  it("preserves unknown vars as-is", function()
    local stub = require("kb.stub")
    local out = stub.substitute({ "{{unknown}}" }, { title = "X" })
    assert.are.same({ "{{unknown}}" }, out)
  end)
end)

describe("kb.stub.derive_title", function()
  it("title-cases the last segment", function()
    local stub = require("kb.stub")
    assert.are.equal("Lena", stub.derive_title("/anywhere/lena.md"))
  end)

  it("converts hyphens to spaces and title-cases each word", function()
    local stub = require("kb.stub")
    assert.are.equal("Labeling Pipeline", stub.derive_title("/x/labeling-pipeline.md"))
  end)

  it("converts underscores to spaces", function()
    local stub = require("kb.stub")
    assert.are.equal("Big Idea", stub.derive_title("/x/big_idea.md"))
  end)
end)

describe("kb.stub.create", function()
  -- Helper: stub vim.fn.confirm to a chosen response.
  local function stub_confirm(answer)
    local original = vim.fn.confirm
    vim.fn.confirm = function(_msg, _choices)
      return answer  -- 1 = Yes, 2 = No
    end
    return function() vim.fn.confirm = original end
  end

  it("does not create file when user picks No", function()
    local vault = fresh_vault()
    local restore = stub_confirm(2)
    local stub = require("kb.stub")
    local target = vault .. "/projects/never.md"
    local result = stub.create(target, "@projects/never")
    restore()
    assert.is_nil(result)
    assert.are.equal(0, vim.fn.filereadable(target))
  end)

  it("creates file with substituted template when user picks Yes", function()
    local vault = fresh_vault()
    write(vault .. "/.templates/entity.md", "# {{title}}\n\nref: {{path}}\n")
    local restore = stub_confirm(1)
    local stub = require("kb.stub")
    local target = vault .. "/projects/labeling-pipeline.md"
    local result = stub.create(target, "@projects/labeling-pipeline")
    restore()
    assert.are.equal(target, result)
    local contents = table.concat(vim.fn.readfile(target), "\n")
    assert.is_truthy(contents:find("# Labeling Pipeline"))
    assert.is_truthy(contents:find("ref: @projects/labeling-pipeline", 1, true))
  end)

  it("creates parent directories as needed", function()
    local vault = fresh_vault()
    local restore = stub_confirm(1)
    local stub = require("kb.stub")
    local target = vault .. "/people/peers/new-person.md"
    stub.create(target, "@people/peers/new-person")
    restore()
    assert.are.equal(1, vim.fn.filereadable(target))
  end)

  it("calls index.refresh_file so new entity is mentionable immediately", function()
    local vault = fresh_vault()
    -- Mock kb.index before requiring kb.stub so the pcall finds it
    local was_called = nil
    package.loaded["kb.index"] = { refresh_file = function(p) was_called = p end }
    local restore = stub_confirm(1)
    local stub = require("kb.stub")
    local target = vault .. "/projects/freshly.md"
    stub.create(target, "@projects/freshly")
    restore()
    assert.are.equal(target, was_called)
  end)

  it("rejects targets outside the vault", function()
    fresh_vault()
    local restore = stub_confirm(1)
    local stub = require("kb.stub")
    local result = stub.create("/tmp/random/elsewhere.md", "/tmp/random/elsewhere.md")
    restore()
    assert.is_nil(result)
    assert.are.equal(0, vim.fn.filereadable("/tmp/random/elsewhere.md"))
  end)

  it("aborts when target already exists", function()
    local vault = fresh_vault()
    local target = vault .. "/projects/existing.md"
    write(target, "ORIGINAL")
    local restore = stub_confirm(1)
    local stub = require("kb.stub")
    local result = stub.create(target, "@projects/existing")
    restore()
    assert.is_nil(result)
    -- File contents unchanged
    assert.are.equal("ORIGINAL", table.concat(vim.fn.readfile(target), "\n"))
  end)
end)
