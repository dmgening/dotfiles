describe("kb.config", function()
  before_each(function()
    package.loaded["kb.config"] = nil
    _G.KB_VAULT_OVERRIDE = nil
    vim.env.KB_VAULT = nil
  end)

  it("returns the default vault path under ~/Documents/ZettelkastenVault", function()
    local config = require("kb.config")
    assert.are.equal(
      vim.fn.expand("~/Documents/ZettelkastenVault"),
      config.vault()
    )
  end)

  it("respects KB_VAULT env var", function()
    vim.env.KB_VAULT = "/tmp/custom-vault"
    package.loaded["kb.config"] = nil
    local config = require("kb.config")
    assert.are.equal("/tmp/custom-vault", config.vault())
  end)

  it("respects _G.KB_VAULT_OVERRIDE (for tests)", function()
    _G.KB_VAULT_OVERRIDE = "/tmp/test-vault"
    package.loaded["kb.config"] = nil
    local config = require("kb.config")
    assert.are.equal("/tmp/test-vault", config.vault())
  end)

  it("axis() returns vault-rooted axis path", function()
    _G.KB_VAULT_OVERRIDE = "/tmp/v"
    package.loaded["kb.config"] = nil
    local config = require("kb.config")
    assert.are.equal("/tmp/v/people", config.axis("people"))
    assert.are.equal("/tmp/v/projects", config.axis("projects"))
    assert.are.equal("/tmp/v/domains", config.axis("domains"))
  end)

  it("axis('all') returns the vault root", function()
    _G.KB_VAULT_OVERRIDE = "/tmp/v"
    package.loaded["kb.config"] = nil
    local config = require("kb.config")
    assert.are.equal("/tmp/v", config.axis("all"))
  end)
end)
