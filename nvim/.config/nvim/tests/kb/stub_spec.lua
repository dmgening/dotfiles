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
