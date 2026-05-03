local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.find"] = nil
  return tmp
end

local function stub_fzf()
  local calls = { files = {}, live_grep = {} }
  package.loaded["fzf-lua"] = {
    files = function(opts) table.insert(calls.files, opts) end,
    live_grep = function(opts) table.insert(calls.live_grep, opts) end,
  }
  return calls
end

describe("kb.find.grep", function()
  it("opens live_grep over vault root by default", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").grep()
    assert.are.equal(1, #calls.live_grep)
    assert.are.equal(vault, calls.live_grep[1].cwd)
  end)

  it("opens live_grep scoped to people when called with 'people'", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").grep("people")
    assert.are.equal(vault .. "/people", calls.live_grep[1].cwd)
  end)

  it("opens live_grep scoped to projects when called with 'projects'", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").grep("projects")
    assert.are.equal(vault .. "/projects", calls.live_grep[1].cwd)
  end)

  it("includes scope in header", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").grep("people")
    local header = calls.live_grep[1].fzf_opts["--header"]
    assert.is_not_nil(header)
    assert.is_true(header:match("people") ~= nil)
  end)

  it("registers actions for direct scope keys and cycle", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").grep()
    local actions = calls.live_grep[1].actions
    assert.is_function(actions["alt-p"])
    assert.is_function(actions["alt-r"])
    assert.is_function(actions["alt-d"])
    assert.is_function(actions["alt-a"])
    assert.is_function(actions["alt-,"])
    assert.is_function(actions["alt-."])
  end)
end)

describe("kb.find.files", function()
  it("opens files over vault root by default", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").files()
    assert.are.equal(1, #calls.files)
    assert.are.equal(vault, calls.files[1].cwd)
  end)

  it("opens files scoped to domains when called with 'domains'", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").files("domains")
    assert.are.equal(vault .. "/domains", calls.files[1].cwd)
  end)

  it("includes scope in header", function()
    local vault = fresh_vault()
    local calls = stub_fzf()
    require("kb.find").files("domains")
    local header = calls.files[1].fzf_opts["--header"]
    assert.is_not_nil(header)
    assert.is_true(header:match("domains") ~= nil)
  end)
end)
