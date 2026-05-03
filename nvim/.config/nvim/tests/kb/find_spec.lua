local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.find"] = nil
  return tmp
end

-- Stub fzf-lua to capture call args
local function stub_fzf()
  local calls = { files = {}, live_grep = {} }
  package.loaded["fzf-lua"] = {
    files = function(opts) table.insert(calls.files, opts) end,
    live_grep = function(opts) table.insert(calls.live_grep, opts) end,
  }
  return calls
end

describe("kb.find.axis", function()
  it("calls fzf-lua.files with vault/people for 'people'", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    local find = require("kb.find")
    find.axis("people")
    assert.are.equal(1, #calls.files)
    assert.are.equal(vault .. "/people", calls.files[1].cwd)
  end)

  it("calls fzf-lua.files with vault/projects for 'projects'", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    local find = require("kb.find")
    find.axis("projects")
    assert.are.equal(vault .. "/projects", calls.files[1].cwd)
  end)

  it("calls fzf-lua.files with vault root for 'all'", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    local find = require("kb.find")
    find.axis("all")
    assert.are.equal(vault, calls.files[1].cwd)
  end)
end)

describe("kb.find.grep", function()
  it("calls fzf-lua.live_grep with vault root", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    local find = require("kb.find")
    find.grep()
    assert.are.equal(1, #calls.live_grep)
    assert.are.equal(vault, calls.live_grep[1].cwd)
  end)
end)
