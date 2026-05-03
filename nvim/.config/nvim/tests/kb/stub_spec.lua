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
