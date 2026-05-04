local function fresh_vault()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  _G.KB_VAULT_OVERRIDE = tmp
  package.loaded["kb.config"] = nil
  package.loaded["kb.at"] = nil
  package.loaded["kb.stub"] = nil
  return tmp
end

describe("kb.at.parse", function()
  it("parses single-segment mention @vanya", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("hi @vanya there", 4)
    assert.are.same({ path = "vanya", raw = "@vanya" }, m)
  end)

  it("parses two-segment mention @projects/payments", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("hi @projects/payments now", 4)
    assert.are.same({ path = "projects/payments", raw = "@projects/payments" }, m)
  end)

  it("parses three-segment mention @people/peers/lena", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("see @people/peers/lena tomorrow", 5)
    assert.are.same({ path = "people/peers/lena", raw = "@people/peers/lena" }, m)
  end)

  it("parses arbitrary-depth nested mention", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("see @people/friends/zedliser today", 20)
    assert.are.same({ path = "people/friends/zedliser", raw = "@people/friends/zedliser" }, m)
  end)

  it("parses mention regardless of cursor position within span", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("see @projects/payments now", 12)
    assert.are.same({ path = "projects/payments", raw = "@projects/payments" }, m)
  end)

  it("returns nil if cursor is not on a mention", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.parse("no mention here", 1))
  end)

  it("does NOT match @ in email-like text (a@b.com)", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("email a@b.com today", 8)
    assert.is_nil(m)
  end)

  it("trims trailing slash from in-flight typing", function()
    fresh_vault()
    local at = require("kb.at")
    local m = at.parse("typing @people/", 8)
    assert.are.same({ path = "people", raw = "@people" }, m)
  end)
end)

describe("kb.at.resolve", function()
  it("resolves a flat-form path", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/projects", "p")
    vim.fn.writefile({ "# Payments" }, vault .. "/projects/payments.md")
    local at = require("kb.at")
    local p = at.resolve({ path = "projects/payments" })
    assert.are.equal(vault .. "/projects/payments.md", p)
  end)

  it("resolves a nested path", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/people/friends", "p")
    vim.fn.writefile({ "# Z" }, vault .. "/people/friends/zedliser.md")
    local at = require("kb.at")
    local p = at.resolve({ path = "people/friends/zedliser" })
    assert.are.equal(vault .. "/people/friends/zedliser.md", p)
  end)

  it("resolves folder form via index.md", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/domains/labeling", "p")
    vim.fn.writefile({ "# L" }, vault .. "/domains/labeling/index.md")
    local at = require("kb.at")
    local p = at.resolve({ path = "domains/labeling" })
    assert.are.equal(vault .. "/domains/labeling/index.md", p)
  end)

  it("prefers flat over folder", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/domains/labeling", "p")
    vim.fn.writefile({ "FLAT" }, vault .. "/domains/labeling.md")
    vim.fn.writefile({ "FOLDER" }, vault .. "/domains/labeling/index.md")
    local at = require("kb.at")
    local p = at.resolve({ path = "domains/labeling" })
    assert.are.equal(vault .. "/domains/labeling.md", p)
  end)

  it("resolves single-segment to vault root", function()
    local vault = fresh_vault()
    vim.fn.writefile({ "# TODO" }, vault .. "/todo.md")
    local at = require("kb.at")
    local p = at.resolve({ path = "todo" })
    assert.are.equal(vault .. "/todo.md", p)
  end)

  it("returns nil when neither flat nor folder exists", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.resolve({ path = "projects/missing" }))
  end)
end)

describe("kb.at.jump", function()
  it("opens the resolved file", function()
    local vault = fresh_vault()
    vim.fn.mkdir(vault .. "/people/friends", "p")
    vim.fn.writefile({ "# Z" }, vault .. "/people/friends/zedliser.md")
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @people/friends/zedliser here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local at = require("kb.at")
    at.jump()
    assert.are.equal(
      vim.fn.resolve(vault .. "/people/friends/zedliser.md"),
      vim.fn.resolve(vim.api.nvim_buf_get_name(0))
    )
    vim.cmd("bwipeout!")
  end)

  it("notifies when stub creation declined (missing file)", function()
    fresh_vault()
    local orig_confirm = vim.fn.confirm
    vim.fn.confirm = function(_msg, _choices) return 2 end  -- No
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @projects/missing here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local notified = nil
    local original = vim.notify
    vim.notify = function(msg, _) notified = msg end
    local at = require("kb.at")
    at.jump()
    vim.notify = original
    vim.fn.confirm = orig_confirm
    assert.is_not_nil(notified)
    assert.is_true(notified:match("not created") ~= nil)
    vim.cmd("bwipeout!")
  end)

  it("notifies when no mention under cursor", function()
    fresh_vault()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "no mention here" })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    local notified = nil
    local original = vim.notify
    vim.notify = function(msg, _) notified = msg end
    local at = require("kb.at")
    at.jump()
    vim.notify = original
    assert.is_not_nil(notified)
    assert.is_true(notified:match("no link or mention") ~= nil)
    vim.cmd("bwipeout!")
  end)
end)

describe("kb.at.parse_link", function()
  it("parses [text](path) at cursor on text", function()
    fresh_vault()
    local at = require("kb.at")
    local link = at.parse_link("see [docs](/foo/bar.md) here", 8)
    assert.are.same({ text = "docs", path = "/foo/bar.md" }, link)
  end)

  it("parses [text](path) at cursor on path", function()
    fresh_vault()
    local at = require("kb.at")
    local link = at.parse_link("see [docs](/foo/bar.md) here", 14)
    assert.are.same({ text = "docs", path = "/foo/bar.md" }, link)
  end)

  it("returns nil when cursor is not on a link", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.parse_link("plain text", 4))
  end)
end)

describe("kb.at.resolve_link", function()
  it("resolves vault-rooted /foo.md", function()
    local vault = fresh_vault()
    local at = require("kb.at")
    -- "current buffer" doesn't matter for rooted paths
    local resolved = at.resolve_link({ path = "/projects/x.md" }, vault .. "/anywhere.md")
    assert.are.equal(vault .. "/projects/x.md", resolved)
  end)

  it("resolves bare filename relative to current buffer", function()
    local vault = fresh_vault()
    local at = require("kb.at")
    local resolved = at.resolve_link(
      { path = "queries.md" },
      vault .. "/domains/labeling/index.md"
    )
    assert.are.equal(vault .. "/domains/labeling/queries.md", resolved)
  end)

  it("resolves ../ paths", function()
    local vault = fresh_vault()
    local at = require("kb.at")
    local resolved = at.resolve_link(
      { path = "../labeling/queries.md" },
      vault .. "/domains/pricing/index.md"
    )
    assert.are.equal(vault .. "/domains/labeling/queries.md", resolved)
  end)

  it("returns http URL as-is (caller handles ui.open)", function()
    fresh_vault()
    local at = require("kb.at")
    local resolved = at.resolve_link({ path = "https://example.com" }, "/anywhere.md")
    assert.are.equal("https://example.com", resolved)
  end)

  it("strips #anchor from the path for resolution", function()
    local vault = fresh_vault()
    local at = require("kb.at")
    local resolved, anchor = at.resolve_link(
      { path = "/projects/x.md#section" },
      vault .. "/anywhere.md"
    )
    assert.are.equal(vault .. "/projects/x.md", resolved)
    assert.are.equal("section", anchor)
  end)
end)

local function write(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(content, "\n"), path)
end

describe("kb.at.jump dispatcher", function()
  it("dispatches @-mention to mention-jump path", function()
    local vault = fresh_vault()
    write(vault .. "/projects/x.md", "")
    -- Open a buffer with cursor on the mention
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @projects/x today" })
    vim.api.nvim_win_set_cursor(0, { 1, 4 })  -- on '@'
    require("kb.at").jump()
    assert.are.equal(
      vim.fn.resolve(vault .. "/projects/x.md"),
      vim.fn.resolve(vim.api.nvim_buf_get_name(0))
    )
  end)

  it("dispatches markdown link to jump_link", function()
    local vault = fresh_vault()
    local p = vault .. "/projects/x.md"
    write(p, "")
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see [x](/projects/x.md) today" })
    vim.api.nvim_win_set_cursor(0, { 1, 4 })  -- on '['
    require("kb.at").jump()
    assert.are.equal(
      vim.fn.resolve(p),
      vim.fn.resolve(vim.api.nvim_buf_get_name(0))
    )
  end)
end)

local function stub_fzf_grep()
  local calls = { grep = {} }
  package.loaded["fzf-lua"] = {
    grep = function(opts) table.insert(calls.grep, opts) end,
  }
  return calls
end

describe("kb.at.backlinks", function()
  it("calls fzf-lua.grep with the canonical mention form", function()
    local vault = fresh_vault()
    local calls = stub_fzf_grep()
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @people/peers/lena here" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    local at = require("kb.at")
    at.backlinks()
    assert.are.equal(1, #calls.grep)
    assert.are.equal(vault, calls.grep[1].cwd)
    assert.are.equal("@people/peers/lena", calls.grep[1].search)
    vim.cmd("bwipeout!")
  end)
end)

describe("kb.at.jump stub creation", function()
  local function stub_confirm(answer)
    local original = vim.fn.confirm
    vim.fn.confirm = function(_msg, _choices) return answer end
    return function() vim.fn.confirm = original end
  end

  it("@-mention to missing target → confirm Yes → file created and opened", function()
    local vault = fresh_vault()
    local restore = stub_confirm(1)
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "look @projects/brand-new now" })
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    require("kb.at").jump()
    restore()
    assert.are.equal(
      vim.fn.resolve(vault .. "/projects/brand-new.md"),
      vim.fn.resolve(vim.api.nvim_buf_get_name(0))
    )
  end)

  it("markdown link to missing target → confirm Yes → file created and opened", function()
    local vault = fresh_vault()
    local restore = stub_confirm(1)
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "[doc](/projects/new-doc.md)" })
    vim.api.nvim_win_set_cursor(0, { 1, 1 })
    require("kb.at").jump()
    restore()
    assert.are.equal(
      vim.fn.resolve(vault .. "/projects/new-doc.md"),
      vim.fn.resolve(vim.api.nvim_buf_get_name(0))
    )
  end)

  it("@-mention to missing target → confirm No → no file created", function()
    local vault = fresh_vault()
    local restore = stub_confirm(2)
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "look @projects/no-thanks now" })
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
    require("kb.at").jump()
    restore()
    assert.are.equal(0, vim.fn.filereadable(vault .. "/projects/no-thanks.md"))
  end)
end)

describe("kb.at.parse_tag", function()
  it("parses #urgent at cursor", function()
    fresh_vault()
    local at = require("kb.at")
    -- "see #urgent now"
    --  1234567890123456
    -- '#' at col 5; cursor anywhere in 5..11 should match
    local t = at.parse_tag("see #urgent now", 6)
    assert.are.same({ tag = "urgent", raw = "#urgent" }, t)
  end)

  it("parses hierarchical #followup/manager", function()
    fresh_vault()
    local at = require("kb.at")
    local t = at.parse_tag("ping #followup/manager today", 8)
    assert.are.same({ tag = "followup/manager", raw = "#followup/manager" }, t)
  end)

  it("parses tag at start of line", function()
    fresh_vault()
    local at = require("kb.at")
    local t = at.parse_tag("#blocked because of X", 1)
    assert.are.same({ tag = "blocked", raw = "#blocked" }, t)
  end)

  it("rejects # preceded by alphanumeric (e.g. abc#notatag)", function()
    fresh_vault()
    local at = require("kb.at")
    -- cursor on the # in `abc#notatag`
    assert.is_nil(at.parse_tag("see abc#notatag here", 8))
  end)

  it("returns nil when cursor is not on a tag", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.parse_tag("plain text only", 4))
  end)

  it("rejects # followed by digit (per index regex: alpha-first)", function()
    fresh_vault()
    local at = require("kb.at")
    assert.is_nil(at.parse_tag("see #123 here", 6))
  end)
end)

describe("kb.at.backlinks dispatch", function()
  it("invokes fzf-lua grep with tag.raw when cursor is on #tag", function()
    fresh_vault()
    -- Stub fzf-lua to capture the search string
    local captured = nil
    package.loaded["fzf-lua"] = {
      grep = function(opts) captured = opts end,
    }
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see #urgent today" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    require("kb.at").backlinks()
    assert.is_not_nil(captured)
    assert.are.equal("#urgent", captured.search)
    package.loaded["fzf-lua"] = nil
  end)

  it("falls back to @-mention search when no tag under cursor", function()
    fresh_vault()
    local captured = nil
    package.loaded["fzf-lua"] = {
      grep = function(opts) captured = opts end,
    }
    vim.cmd("enew")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "see @projects/x today" })
    vim.api.nvim_win_set_cursor(0, { 1, 5 })
    require("kb.at").backlinks()
    assert.is_not_nil(captured)
    assert.are.equal("@projects/x", captured.search)
    package.loaded["fzf-lua"] = nil
  end)
end)
