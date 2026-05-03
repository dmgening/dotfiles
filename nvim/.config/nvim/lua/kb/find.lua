local config = require("kb.config")

local M = {}

local SCOPES = { "people", "projects", "domains", "all" }

local function scope_index(name)
  for i, s in ipairs(SCOPES) do
    if s == name then return i end
  end
  return #SCOPES -- default to "all"
end

local function next_scope(current)
  return SCOPES[(scope_index(current) % #SCOPES) + 1]
end

local function prev_scope(current)
  return SCOPES[((scope_index(current) - 2) % #SCOPES) + 1]
end

local function scope_cwd(scope)
  if scope == "all" then return config.vault() end
  return config.vault() .. "/" .. scope
end

local function header_for(label, scope)
  return string.format(
    "kb-%s [%s] | <A-p/r/d/a> direct | <A-,/.> cycle",
    label, scope
  )
end

local function fzf()
  return require("fzf-lua")
end

local function actions_for(open_fn, scope)
  return {
    ["alt-p"] = function(_, opts) open_fn("people",   opts.last_query) end,
    ["alt-r"] = function(_, opts) open_fn("projects", opts.last_query) end,
    ["alt-d"] = function(_, opts) open_fn("domains",  opts.last_query) end,
    ["alt-a"] = function(_, opts) open_fn("all",      opts.last_query) end,
    ["alt-,"] = function(_, opts) open_fn(prev_scope(scope), opts.last_query) end,
    ["alt-."] = function(_, opts) open_fn(next_scope(scope), opts.last_query) end,
  }
end

function M.grep(scope, query)
  scope = scope or "all"
  fzf().live_grep({
    cwd = scope_cwd(scope),
    query = query,
    prompt = "kb-grep> ",
    fzf_opts = { ["--header"] = header_for("grep", scope) },
    actions = actions_for(M.grep, scope),
  })
end

function M.files(scope, query)
  scope = scope or "all"
  fzf().files({
    cwd = scope_cwd(scope),
    query = query,
    prompt = "kb-files> ",
    fzf_opts = { ["--header"] = header_for("files", scope) },
    actions = actions_for(M.files, scope),
  })
end

return M
